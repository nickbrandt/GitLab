require 'spec_helper'

describe Geo::AttachmentRegistryFinder, :geo do
  include ::EE::GeoHelpers

  # Using let() instead of set() because set() does not work properly
  # when using the :delete DatabaseCleaner strategy, which is required for FDW
  # tests because a foreign table can't see changes inside a transaction of a
  # different connection.
  let(:secondary) { create(:geo_node) }

  let(:synced_group) { create(:group) }
  let(:synced_subgroup) { create(:group, parent: synced_group) }
  let(:unsynced_group) { create(:group) }
  let(:synced_project) { create(:project, group: synced_group) }
  let(:synced_project_in_nested_group) { create(:project, group: synced_subgroup) }
  let(:unsynced_project) { create(:project, :broken_storage, group: unsynced_group) }

  let(:upload_1) { create(:upload, model: synced_group) }
  let(:upload_2) { create(:upload, model: unsynced_group) }
  let(:upload_3) { create(:upload, :issuable_upload, model: synced_project) }
  let(:upload_4) { create(:upload, model: unsynced_project) }
  let(:upload_5) { create(:upload, model: synced_project) }

  subject { described_class.new(current_node: secondary) }

  before do
    stub_current_geo_node(secondary)
  end

  shared_examples 'finds all the things' do
    describe '#find_unsynced' do
      it 'returns uploads without an entry on the tracking database' do
        create(:geo_file_registry, :avatar, file_id: upload_1.id)

        uploads = subject.find_unsynced(batch_size: 10)

        expect(uploads).to match_ids(upload_2, upload_3, upload_4)
      end

      it 'excludes uploads in the except_file_ids option' do
        uploads = subject.find_unsynced(batch_size: 10, except_file_ids: [upload_2.id])

        expect(uploads).to match_ids(upload_1, upload_3, upload_4)
      end

      it 'excludes remote uploads' do
        upload_1.update!(store: ObjectStorage::Store::REMOTE)

        uploads = subject.find_unsynced(batch_size: 10)

        expect(uploads).to match_ids(upload_2, upload_3, upload_4)
      end
    end

    describe '#find_migrated_local' do
      it 'returns uploads stored remotely and successfully synced locally' do
        upload = create(:upload, :object_storage, model: synced_group)
        create(:geo_file_registry, :avatar, file_id: upload.id)

        uploads = subject.find_migrated_local(batch_size: 100)

        expect(uploads).to match_ids(upload)
      end

      it 'excludes uploads stored remotely, but not synced yet' do
        create(:upload, :object_storage, model: synced_group)

        uploads = subject.find_migrated_local(batch_size: 100)

        expect(uploads).to be_empty
      end

      it 'excludes synced uploads that are stored locally' do
        create(:geo_file_registry, :avatar, file_id: upload_5.id)

        uploads = subject.find_migrated_local(batch_size: 100)

        expect(uploads).to be_empty
      end

      it 'excludes except_file_ids' do
        upload_a = create(:upload, :object_storage, model: synced_group)
        upload_b = create(:upload, :object_storage, model: unsynced_group)
        create(:geo_file_registry, :avatar, file_id: upload_a.id)
        create(:geo_file_registry, :avatar, file_id: upload_b.id)

        uploads = subject.find_migrated_local(batch_size: 10, except_file_ids: [upload_a.id])

        expect(uploads).to match_ids(upload_b)
      end
    end
  end

  shared_examples 'counts all the things' do
    describe '#count_syncable' do
      let!(:upload_1) { create(:upload, model: synced_group) }
      let!(:upload_2) { create(:upload, model: unsynced_group) }
      let!(:upload_3) { create(:upload, :issuable_upload, model: synced_project_in_nested_group) }
      let!(:upload_4) { create(:upload, model: unsynced_project) }
      let!(:upload_5) { create(:upload, :personal_snippet_upload) }

      it 'counts attachments' do
        expect(subject.count_syncable).to eq 5
      end

      it 'ignores remote attachments' do
        upload_1.update!(store: ObjectStorage::Store::REMOTE)

        expect(subject.count_syncable).to eq 4
      end

      context 'with selective sync by namespace' do
        before do
          secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])
        end

        it 'counts attachments' do
          expect(subject.count_syncable).to eq 3
        end

        it 'ignores remote attachments' do
          upload_1.update!(store: ObjectStorage::Store::REMOTE)

          expect(subject.count_syncable).to eq 2
        end
      end

      context 'with selective sync by shard' do
        before do
          secondary.update!(selective_sync_type: 'shards', selective_sync_shards: ['broken'])
        end

        it 'counts attachments' do
          expect(subject.count_syncable).to eq 3
        end

        it 'ignores remote attachments' do
          upload_4.update!(store: ObjectStorage::Store::REMOTE)

          expect(subject.count_syncable).to eq 2
        end
      end
    end

    describe '#count_synced' do
      let!(:upload_1) { create(:upload, model: synced_group) }
      let!(:upload_2) { create(:upload, model: unsynced_group) }
      let!(:upload_3) { create(:upload, :issuable_upload, model: synced_project_in_nested_group) }
      let!(:upload_4) { create(:upload, model: unsynced_project) }
      let!(:upload_5) { create(:upload, :personal_snippet_upload) }
      let(:upload_remote_1) { create(:upload, :object_storage, model: synced_project) }

      it 'counts attachments that have been synced' do
        create(:geo_file_registry, :attachment, :failed, file_id: upload_1.id)
        create(:geo_file_registry, :attachment, file_id: upload_2.id)
        create(:geo_file_registry, :attachment, file_id: upload_3.id)
        create(:geo_file_registry, :attachment, file_id: upload_4.id)
        create(:geo_file_registry, :attachment, file_id: upload_5.id)

        expect(subject.count_synced).to eq 4
      end

      it 'ignores remote attachments' do
        create(:geo_file_registry, :attachment, file_id: upload_remote_1.id)
        create(:geo_file_registry, :attachment, file_id: upload_2.id)
        create(:geo_file_registry, :attachment, file_id: upload_3.id)

        expect(subject.count_synced).to eq 2
      end

      context 'with selective sync by namespace' do
        before do
          secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])
        end

        it 'counts attachments that has been synced' do
          create(:geo_file_registry, :attachment, :failed, file_id: upload_1.id)
          create(:geo_file_registry, :attachment, file_id: upload_2.id)
          create(:geo_file_registry, :attachment, file_id: upload_3.id)
          create(:geo_file_registry, :attachment, file_id: upload_4.id)
          create(:geo_file_registry, :attachment, file_id: upload_5.id)

          expect(subject.count_synced).to eq 2
        end

        it 'ignores remote attachments' do
          create(:geo_file_registry, :attachment, file_id: upload_remote_1.id)
          create(:geo_file_registry, :attachment, file_id: upload_2.id)
          create(:geo_file_registry, :attachment, file_id: upload_3.id)

          expect(subject.count_synced).to eq 1
        end
      end

      context 'with selective sync by shard' do
        before do
          secondary.update!(selective_sync_type: 'shards', selective_sync_shards: ['broken'])
        end

        it 'counts attachments that has been synced' do
          create(:geo_file_registry, :attachment, :failed, file_id: upload_1.id)
          create(:geo_file_registry, :attachment, file_id: upload_2.id)
          create(:geo_file_registry, :attachment, file_id: upload_3.id)
          create(:geo_file_registry, :attachment, file_id: upload_4.id)
          create(:geo_file_registry, :attachment, file_id: upload_5.id)

          expect(subject.count_synced).to eq 3
        end

        it 'ignores remote attachments' do
          create(:geo_file_registry, :attachment, file_id: upload_remote_1.id)
          create(:geo_file_registry, :attachment, file_id: upload_2.id)
          create(:geo_file_registry, :attachment, file_id: upload_3.id)

          expect(subject.count_synced).to eq 1
        end
      end
    end

    describe '#count_failed' do
      let!(:upload_1) { create(:upload, model: synced_group) }
      let!(:upload_2) { create(:upload, model: unsynced_group) }
      let!(:upload_3) { create(:upload, :issuable_upload, model: synced_project_in_nested_group) }
      let!(:upload_4) { create(:upload, model: unsynced_project) }
      let!(:upload_5) { create(:upload, :personal_snippet_upload) }
      let(:upload_remote_1) { create(:upload, :object_storage, model: synced_project) }

      it 'counts attachments that sync has failed' do
        create(:geo_file_registry, :attachment, :failed, file_id: upload_1.id)
        create(:geo_file_registry, :attachment, file_id: upload_2.id)
        create(:geo_file_registry, :attachment, :failed, file_id: upload_3.id)
        create(:geo_file_registry, :attachment, :failed, file_id: upload_4.id)
        create(:geo_file_registry, :attachment, :failed, file_id: upload_5.id)

        expect(subject.count_failed).to eq 4
      end

      it 'ignores remote attachments' do
        create(:geo_file_registry, :attachment, :failed, file_id: upload_remote_1.id)
        create(:geo_file_registry, :attachment, :failed, file_id: upload_2.id)
        create(:geo_file_registry, :attachment, :failed, file_id: upload_3.id)

        expect(subject.count_failed).to eq 2
      end

      context 'with selective sync by namespace' do
        before do
          secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])
        end

        it 'counts attachments that sync has failed' do
          create(:geo_file_registry, :attachment, file_id: upload_1.id)
          create(:geo_file_registry, :attachment, :failed, file_id: upload_2.id)
          create(:geo_file_registry, :attachment, :failed, file_id: upload_3.id)
          create(:geo_file_registry, :attachment, :failed, file_id: upload_4.id)
          create(:geo_file_registry, :attachment, :failed, file_id: upload_5.id)

          expect(subject.count_failed).to eq 2
        end

        it 'ignores remote attachments' do
          create(:geo_file_registry, :attachment, :failed, file_id: upload_remote_1.id)
          create(:geo_file_registry, :attachment, :failed, file_id: upload_2.id)
          create(:geo_file_registry, :attachment, :failed, file_id: upload_3.id)

          expect(subject.count_failed).to eq 1
        end
      end

      context 'with selective sync by shard' do
        before do
          secondary.update!(selective_sync_type: 'shards', selective_sync_shards: ['broken'])
        end

        it 'counts attachments that sync has failed' do
          create(:geo_file_registry, :attachment, file_id: upload_1.id)
          create(:geo_file_registry, :attachment, :failed, file_id: upload_2.id)
          create(:geo_file_registry, :attachment, :failed, file_id: upload_3.id)
          create(:geo_file_registry, :attachment, :failed, file_id: upload_4.id)
          create(:geo_file_registry, :attachment, :failed, file_id: upload_5.id)

          expect(subject.count_failed).to eq 3
        end

        it 'ignores remote attachments' do
          create(:geo_file_registry, :attachment, :failed, file_id: upload_remote_1.id)
          create(:geo_file_registry, :attachment, :failed, file_id: upload_2.id)
          create(:geo_file_registry, :attachment, :failed, file_id: upload_3.id)

          expect(subject.count_failed).to eq 1
        end
      end
    end

    describe '#count_synced_missing_on_primary' do
      let!(:upload_1) { create(:upload, model: synced_group) }
      let!(:upload_2) { create(:upload, model: unsynced_group) }
      let!(:upload_3) { create(:upload, :issuable_upload, model: synced_project_in_nested_group) }
      let!(:upload_4) { create(:upload, model: unsynced_project) }
      let!(:upload_5) { create(:upload, :personal_snippet_upload) }
      let(:upload_remote_1) { create(:upload, :object_storage, model: synced_project) }

      it 'counts attachments that have been synced and are missing on the primary' do
        create(:geo_file_registry, :attachment, :failed, file_id: upload_1.id, missing_on_primary: true)
        create(:geo_file_registry, :attachment, file_id: upload_2.id, missing_on_primary: true)
        create(:geo_file_registry, :attachment, file_id: upload_3.id, missing_on_primary: true)
        create(:geo_file_registry, :attachment, file_id: upload_4.id, missing_on_primary: false)
        create(:geo_file_registry, :attachment, file_id: upload_5.id, missing_on_primary: true)

        expect(subject.count_synced_missing_on_primary).to eq 3
      end

      it 'ignores remote attachments' do
        create(:geo_file_registry, :attachment, file_id: upload_remote_1.id, missing_on_primary: true)
        create(:geo_file_registry, :attachment, file_id: upload_2.id, missing_on_primary: true)
        create(:geo_file_registry, :attachment, file_id: upload_3.id, missing_on_primary: true)

        expect(subject.count_synced_missing_on_primary).to eq 2
      end

      context 'with selective sync by namespace' do
        before do
          secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])
        end

        it 'counts attachments that have been synced and are missing on the primary' do
          create(:geo_file_registry, :attachment, :failed, file_id: upload_1.id, missing_on_primary: true)
          create(:geo_file_registry, :attachment, file_id: upload_2.id, missing_on_primary: true)
          create(:geo_file_registry, :attachment, file_id: upload_3.id, missing_on_primary: true)
          create(:geo_file_registry, :attachment, file_id: upload_4.id, missing_on_primary: true)
          create(:geo_file_registry, :attachment, file_id: upload_5.id, missing_on_primary: true)

          expect(subject.count_synced_missing_on_primary).to eq 2
        end

        it 'ignores remote attachments' do
          create(:geo_file_registry, :attachment, file_id: upload_remote_1.id, missing_on_primary: true)
          create(:geo_file_registry, :attachment, file_id: upload_2.id, missing_on_primary: true)
          create(:geo_file_registry, :attachment, file_id: upload_3.id, missing_on_primary: true)

          expect(subject.count_synced_missing_on_primary).to eq 1
        end
      end

      context 'with selective sync by shard' do
        before do
          secondary.update!(selective_sync_type: 'shards', selective_sync_shards: ['broken'])
        end

        it 'counts attachments that have been synced and are missing on the primary' do
          create(:geo_file_registry, :attachment, :failed, file_id: upload_1.id, missing_on_primary: true)
          create(:geo_file_registry, :attachment, file_id: upload_2.id, missing_on_primary: true)
          create(:geo_file_registry, :attachment, file_id: upload_3.id, missing_on_primary: true)
          create(:geo_file_registry, :attachment, file_id: upload_4.id, missing_on_primary: true)
          create(:geo_file_registry, :attachment, file_id: upload_5.id, missing_on_primary: true)

          expect(subject.count_synced_missing_on_primary).to eq 3
        end

        it 'ignores remote attachments' do
          create(:geo_file_registry, :attachment, file_id: upload_remote_1.id, missing_on_primary: true)
          create(:geo_file_registry, :attachment, file_id: upload_2.id, missing_on_primary: true)
          create(:geo_file_registry, :attachment, file_id: upload_3.id, missing_on_primary: true)

          expect(subject.count_synced_missing_on_primary).to eq 1
        end
      end
    end

    describe '#count_registry' do
      let!(:upload_1) { create(:upload, model: synced_group) }
      let!(:upload_2) { create(:upload, model: unsynced_group) }
      let!(:upload_3) { create(:upload, :issuable_upload, model: synced_project_in_nested_group) }
      let!(:upload_4) { create(:upload, model: unsynced_project) }
      let!(:upload_5) { create(:upload, :personal_snippet_upload) }
      let(:upload_remote_1) { create(:upload, :object_storage, model: synced_project) }

      it 'counts file registries for attachments' do
        create(:geo_file_registry, :attachment, :failed, file_id: upload_1.id)
        create(:geo_file_registry, :attachment, file_id: upload_2.id, missing_on_primary: true)
        create(:geo_file_registry, :attachment, file_id: upload_3.id)
        create(:geo_file_registry, :attachment, file_id: upload_4.id, missing_on_primary: false)
        create(:geo_file_registry, :attachment, file_id: upload_5.id)

        expect(subject.count_registry).to eq 5
      end

      context 'with selective sync by namespace' do
        before do
          secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])
        end

        it 'counts file registries for attachments' do
          create(:geo_file_registry, :attachment, :failed, file_id: upload_1.id, missing_on_primary: true)
          create(:geo_file_registry, :attachment, file_id: upload_2.id)
          create(:geo_file_registry, :attachment, file_id: upload_3.id)
          create(:geo_file_registry, :attachment, file_id: upload_4.id)
          create(:geo_file_registry, :attachment, file_id: upload_5.id, missing_on_primary: true)

          expect(subject.count_registry).to eq 3
        end
      end

      context 'with selective sync by shard' do
        before do
          secondary.update!(selective_sync_type: 'shards', selective_sync_shards: ['broken'])
        end

        it 'counts file registries for attachments' do
          create(:geo_file_registry, :attachment, :failed, file_id: upload_1.id)
          create(:geo_file_registry, :attachment, file_id: upload_2.id, missing_on_primary: true)
          create(:geo_file_registry, :attachment, file_id: upload_3.id)
          create(:geo_file_registry, :attachment, file_id: upload_4.id)
          create(:geo_file_registry, :attachment, file_id: upload_5.id)

          expect(subject.count_registry).to eq 3
        end
      end
    end
  end

  it_behaves_like 'a file registry finder'
end
