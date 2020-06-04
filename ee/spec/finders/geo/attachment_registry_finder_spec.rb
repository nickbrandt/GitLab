# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::AttachmentRegistryFinder, :geo, :geo_fdw do
  include ::EE::GeoHelpers

  # Using let() instead of set() because set() does not work properly
  # when using the :delete DatabaseCleaner strategy, which is required
  # for FDW tests because a foreign table can't see changes inside a
  # transaction of a different connection.
  let(:secondary) { create(:geo_node) }

  let(:synced_group) { create(:group) }
  let(:synced_subgroup) { create(:group, parent: synced_group) }
  let(:unsynced_group) { create(:group) }

  let(:synced_project) { create(:project, group: synced_group) }
  let(:synced_project_in_nested_group) { create(:project, group: synced_subgroup) }
  let(:unsynced_project) { create(:project, :broken_storage, group: unsynced_group) }

  subject { described_class.new(current_node_id: secondary.id) }

  before do
    stub_current_geo_node(secondary)
  end

  let!(:upload_synced_group) { create(:upload, model: synced_group) }
  let!(:upload_unsynced_group) { create(:upload, model: unsynced_group) }
  let!(:upload_issuable_synced_nested_project) { create(:upload, :issuable_upload, model: synced_project_in_nested_group) }
  let!(:upload_unsynced_project) { create(:upload, model: unsynced_project) }
  let!(:upload_synced_project) { create(:upload, model: synced_project) }
  let!(:upload_personal_snippet) { create(:upload, :personal_snippet_upload) }
  let!(:upload_remote_synced_project) { create(:upload, :object_storage, model: synced_project) }
  let!(:upload_remote_unsynced_project) { create(:upload, :object_storage, model: unsynced_project) }
  let!(:upload_remote_synced_group) { create(:upload, :object_storage, model: synced_group) }

  context 'finds all the things' do
    describe '#find_unsynced' do
      before do
        create(:geo_upload_registry, :avatar, file_id: upload_synced_group.id)
        create(:geo_upload_registry, :avatar, file_id: upload_unsynced_group.id)
        create(:geo_upload_registry, :avatar, file_id: upload_remote_synced_project.id)
      end

      context 'with object storage sync enabled' do
        it 'returns attachments without an entry on the tracking database' do
          attachments = subject.find_unsynced(batch_size: 10)

          expect(attachments).to match_ids(upload_issuable_synced_nested_project, upload_unsynced_project,
                                           upload_synced_project, upload_personal_snippet, upload_remote_unsynced_project,
                                           upload_remote_synced_group)
        end

        it 'returns attachments without an entry on the tracking database, excluding from exception list' do
          attachments = subject.find_unsynced(batch_size: 10, except_ids: [upload_issuable_synced_nested_project.id])

          expect(attachments).to match_ids(upload_unsynced_project, upload_synced_project, upload_personal_snippet,
                                           upload_remote_unsynced_project, upload_remote_synced_group)
        end
      end

      context 'with object storage sync disabled' do
        let(:secondary) { create(:geo_node, :local_storage_only) }

        it 'returns local attachments only' do
          attachments = subject.find_unsynced(batch_size: 10, except_ids: [upload_synced_project.id])

          expect(attachments).to match_ids(upload_issuable_synced_nested_project, upload_unsynced_project,
                                           upload_personal_snippet)
        end
      end

      context 'with selective sync by namespace' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'namespaces', namespaces: [synced_group]) }

        it 'returns attachments without an entry on the tracking database, excluding from exception list' do
          attachments = subject.find_unsynced(batch_size: 10, except_ids: [upload_synced_project.id])

          expect(attachments).to match_ids(upload_issuable_synced_nested_project, upload_personal_snippet,
                                           upload_remote_synced_group)
        end
      end

      context 'with selective sync by shard' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'shards', selective_sync_shards: ['broken']) }

        it 'returns attachments without an entry on the tracking database' do
          attachments = subject.find_unsynced(batch_size: 10)

          expect(attachments).to match_ids(upload_unsynced_project, upload_personal_snippet,
                                           upload_remote_unsynced_project)
        end
      end
    end

    describe '#find_migrated_local' do
      before do
        create(:geo_upload_registry, :avatar, file_id: upload_remote_synced_project.id)
        create(:geo_upload_registry, :avatar, file_id: upload_remote_unsynced_project.id)
      end

      it 'returns attachments stored remotely and successfully synced locally' do
        attachments = subject.find_migrated_local(batch_size: 100, except_ids: [upload_remote_unsynced_project.id])

        expect(attachments).to match_ids(upload_remote_synced_project)
      end

      it 'excludes attachments stored remotely, but not synced yet' do
        attachments = subject.find_migrated_local(batch_size: 100)

        expect(attachments).to match_ids(upload_remote_synced_project, upload_remote_unsynced_project)
      end

      context 'with selective sync by namespace' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'namespaces', namespaces: [synced_group]) }

        it 'returns attachments stored remotely and successfully synced locally' do
          attachments = subject.find_migrated_local(batch_size: 10)

          expect(attachments).to match_ids(upload_remote_synced_project)
        end
      end

      context 'with selective sync by shard' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'shards', selective_sync_shards: ['broken']) }

        it 'returns attachments stored remotely and successfully synced locally' do
          attachments = subject.find_migrated_local(batch_size: 10)

          expect(attachments).to match_ids(upload_remote_unsynced_project)
        end
      end
    end
  end

  context 'counts all the things' do
    describe '#count_synced' do
      before do
        create(:geo_upload_registry, :attachment, :failed, file_id: upload_synced_group.id)
        create(:geo_upload_registry, :attachment, file_id: upload_unsynced_group.id)
        create(:geo_upload_registry, :attachment, file_id: upload_issuable_synced_nested_project.id)
        create(:geo_upload_registry, :attachment, file_id: upload_unsynced_project.id)
        create(:geo_upload_registry, :attachment, file_id: upload_synced_project.id)
        create(:geo_upload_registry, :attachment, file_id: upload_personal_snippet.id)
        create(:geo_upload_registry, :attachment, file_id: upload_remote_synced_project.id)
        create(:geo_upload_registry, :attachment, file_id: upload_remote_unsynced_project.id)
      end

      context 'with object storage sync enabled' do
        it 'counts attachments that have been synced' do
          expect(subject.count_synced).to eq 7
        end
      end

      context 'with object storage sync disabled' do
        let(:secondary) { create(:geo_node, :local_storage_only) }

        it 'counts only local attachments that have been synced' do
          expect(subject.count_synced).to eq 5
        end
      end

      context 'with selective sync by namespace' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'namespaces', namespaces: [synced_group]) }

        it 'counts attachments that has been synced' do
          expect(subject.count_synced).to eq 4
        end
      end

      context 'with selective sync by shard' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'shards', selective_sync_shards: ['broken']) }

        it 'counts attachments that has been synced' do
          expect(subject.count_synced).to eq 4
        end
      end
    end

    describe '#count_failed' do
      before do
        create(:geo_upload_registry, :attachment, file_id: upload_synced_group.id)
        create(:geo_upload_registry, :attachment, :failed, file_id: upload_unsynced_group.id)
        create(:geo_upload_registry, :attachment, :failed, file_id: upload_issuable_synced_nested_project.id)
        create(:geo_upload_registry, :attachment, :failed, file_id: upload_unsynced_project.id)
        create(:geo_upload_registry, :attachment, :failed, file_id: upload_synced_project.id)
        create(:geo_upload_registry, :attachment, :failed, file_id: upload_personal_snippet.id)
        create(:geo_upload_registry, :attachment, :failed, file_id: upload_remote_synced_project.id)
        create(:geo_upload_registry, :attachment, :failed, file_id: upload_remote_unsynced_project.id)
      end

      context 'with object storage sync enabled' do
        it 'counts attachments that sync has failed' do
          expect(subject.count_failed).to eq 7
        end
      end

      context 'with object storage sync disabled' do
        let(:secondary) { create(:geo_node, :local_storage_only) }

        it 'counts only local attachments that have failed' do
          expect(subject.count_failed).to eq 5
        end
      end

      context 'with selective sync by namespace' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'namespaces', namespaces: [synced_group]) }

        it 'counts attachments that sync has failed' do
          expect(subject.count_failed).to eq 4
        end
      end

      context 'with selective sync by shard' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'shards', selective_sync_shards: ['broken']) }

        it 'counts attachments that sync has failed' do
          expect(subject.count_failed).to eq 4
        end
      end
    end

    describe '#count_synced_missing_on_primary' do
      before do
        create(:geo_upload_registry, :attachment, :failed, file_id: upload_synced_group.id, missing_on_primary: true)
        create(:geo_upload_registry, :attachment, file_id: upload_unsynced_group.id, missing_on_primary: true)
        create(:geo_upload_registry, :attachment, file_id: upload_issuable_synced_nested_project.id, missing_on_primary: true)
        create(:geo_upload_registry, :attachment, file_id: upload_unsynced_project.id, missing_on_primary: false)
        create(:geo_upload_registry, :attachment, file_id: upload_synced_project.id, missing_on_primary: true)
        create(:geo_upload_registry, :attachment, file_id: upload_personal_snippet.id, missing_on_primary: true)
        create(:geo_upload_registry, :attachment, file_id: upload_remote_synced_project.id, missing_on_primary: true)
        create(:geo_upload_registry, :attachment, file_id: upload_remote_unsynced_project.id, missing_on_primary: true)
      end

      context 'with object storage sync enabled' do
        it 'counts attachments that have been synced and are missing on the primary' do
          expect(subject.count_synced_missing_on_primary).to eq 6
        end
      end

      context 'with object storage sync disabled' do
        let(:secondary) { create(:geo_node, :local_storage_only) }

        it 'counts only local attachments that have been synced and are missing on the primary' do
          expect(subject.count_synced_missing_on_primary).to eq 4
        end
      end

      context 'with selective sync by namespace' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'namespaces', namespaces: [synced_group]) }

        it 'counts attachments that have been synced and are missing on the primary' do
          expect(subject.count_synced_missing_on_primary).to eq 4
        end
      end

      context 'with selective sync by shard' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'shards', selective_sync_shards: ['broken']) }

        it 'counts attachments that have been synced, are missing on the primary' do
          expect(subject.count_synced_missing_on_primary).to eq 3
        end
      end
    end

    describe '#count_syncable' do
      context 'with object storage sync enabled' do
        it 'counts attachments' do
          expect(subject.count_syncable).to eq 9
        end
      end

      context 'with object storage sync disabled' do
        let(:secondary) { create(:geo_node, :local_storage_only) }

        it 'counts only local attachments' do
          expect(subject.count_syncable).to eq 6
        end
      end

      context 'with selective sync by namespace' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'namespaces', namespaces: [synced_group]) }

        it 'counts attachments' do
          expect(subject.count_syncable).to eq 6
        end
      end

      context 'with selective sync by shard' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'shards', selective_sync_shards: ['broken']) }

        it 'counts attachments' do
          expect(subject.count_syncable).to eq 4
        end
      end
    end

    describe '#count_registry' do
      before do
        create(:geo_upload_registry, :attachment, :failed, file_id: upload_synced_group.id)
        create(:geo_upload_registry, :attachment, file_id: upload_unsynced_group.id, missing_on_primary: true)
        create(:geo_upload_registry, :attachment, file_id: upload_issuable_synced_nested_project.id)
        create(:geo_upload_registry, :attachment, file_id: upload_unsynced_project.id, missing_on_primary: false)
        create(:geo_upload_registry, :attachment, file_id: upload_synced_project.id)
        create(:geo_upload_registry, :attachment, file_id: upload_personal_snippet.id)
        create(:geo_upload_registry, :attachment, file_id: upload_remote_synced_project.id, missing_on_primary: true)
        create(:geo_upload_registry, :attachment, file_id: upload_remote_unsynced_project.id, missing_on_primary: true)
        create(:geo_upload_registry, :attachment, file_id: upload_remote_synced_group.id, missing_on_primary: true)
      end

      context 'with object storage sync enabled' do
        it 'counts file registries for attachments' do
          expect(subject.count_registry).to eq 9
        end
      end

      context 'with object storage sync disabled' do
        let(:secondary) { create(:geo_node, :local_storage_only) }

        it 'does not apply local attachments only restriction' do
          expect(subject.count_registry).to eq 9
        end
      end

      context 'with selective sync by namespace' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'namespaces', namespaces: [synced_group]) }

        it 'does not apply the selective sync restriction' do
          expect(subject.count_registry).to eq 9
        end
      end

      context 'with selective sync by shard' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'shards', selective_sync_shards: ['broken']) }

        it 'does not apply the selective sync restriction' do
          expect(subject.count_registry).to eq 9
        end
      end
    end

    describe '#find_registry_differences' do
      it 'returns untracked IDs as well as tracked IDs that are unused', :aggregate_failures do
        max_id = Upload.maximum(:id)
        create(:geo_upload_registry, :avatar, file_id: upload_synced_group.id)
        create(:geo_upload_registry, :file, file_id: upload_issuable_synced_nested_project.id)
        create(:geo_upload_registry, :avatar, file_id: upload_synced_project.id)
        create(:geo_upload_registry, :personal_file, file_id: upload_personal_snippet.id)
        create(:geo_upload_registry, :avatar, file_id: upload_remote_synced_project.id)
        unused_registry_1 = create(:geo_upload_registry, :attachment, file_id: max_id + 1)
        unused_registry_2 = create(:geo_upload_registry, :personal_file, file_id: max_id + 2)
        range = 1..(max_id + 2)

        untracked, unused = subject.find_registry_differences(range)

        expected_untracked = [
          [upload_unsynced_group.id, 'avatar'],
          [upload_unsynced_project.id, 'avatar'],
          [upload_remote_unsynced_project.id, 'avatar'],
          [upload_remote_synced_group.id, 'avatar']
        ]

        expected_unused = [
          [unused_registry_1.file_id, 'attachment'],
          [unused_registry_2.file_id, 'personal_file']
        ]

        expect(untracked).to match_array(expected_untracked)
        expect(unused).to match_array(expected_unused)
      end
    end
  end
end
