# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::AttachmentRegistryFinder, :geo do
  include ::EE::GeoHelpers

  let_it_be(:secondary) { create(:geo_node) }

  let_it_be(:synced_group) { create(:group) }
  let_it_be(:synced_subgroup) { create(:group, parent: synced_group) }
  let_it_be(:unsynced_group) { create(:group) }
  let_it_be(:synced_project) { create(:project, group: synced_group) }
  let_it_be(:synced_project_in_nested_group) { create(:project, group: synced_subgroup) }
  let_it_be(:unsynced_project) { create(:project, :broken_storage, group: unsynced_group) }

  let_it_be(:upload_1) { create(:upload, model: synced_group) }
  let_it_be(:upload_2) { create(:upload, model: unsynced_group) }
  let_it_be(:upload_3) { create(:upload, :issuable_upload, model: synced_project_in_nested_group) }
  let_it_be(:upload_4) { create(:upload, model: unsynced_project) }
  let_it_be(:upload_5) { create(:upload, model: synced_project) }
  let_it_be(:upload_6) { create(:upload, :personal_snippet_upload) }
  let_it_be(:upload_7) { create(:upload, :object_storage, model: synced_project) }
  let_it_be(:upload_8) { create(:upload, :object_storage, model: unsynced_project) }
  let_it_be(:upload_9) { create(:upload, :object_storage, model: synced_group) }

  before do
    stub_current_geo_node(secondary)
  end

  subject { described_class.new(current_node_id: secondary.id) }

  describe '#count_syncable' do
    it 'counts registries for uploads' do
      create(:geo_upload_registry, :attachment, :failed, file_id: upload_1.id)
      create(:geo_upload_registry, :attachment, file_id: upload_2.id, missing_on_primary: true)
      create(:geo_upload_registry, :attachment, :never_synced, file_id: upload_3.id)
      create(:geo_upload_registry, :attachment, :failed, file_id: upload_4.id)
      create(:geo_upload_registry, :attachment, file_id: upload_5.id, missing_on_primary: true, retry_at: 1.day.ago)
      create(:geo_upload_registry, :attachment, :failed, file_id: upload_6.id)
      create(:geo_upload_registry, :attachment, file_id: upload_7.id, missing_on_primary: true)
      create(:geo_upload_registry, :attachment, :never_synced, file_id: upload_8.id)

      expect(subject.count_syncable).to eq 8
    end
  end

  describe '#count_registry' do
    it 'counts registries for uploads' do
      create(:geo_upload_registry, :attachment, :failed, file_id: upload_1.id)
      create(:geo_upload_registry, :attachment, file_id: upload_2.id, missing_on_primary: true)
      create(:geo_upload_registry, :attachment, :never_synced, file_id: upload_3.id)
      create(:geo_upload_registry, :attachment, :failed, file_id: upload_4.id)
      create(:geo_upload_registry, :attachment, file_id: upload_5.id, missing_on_primary: true, retry_at: 1.day.ago)
      create(:geo_upload_registry, :attachment, :failed, file_id: upload_6.id)
      create(:geo_upload_registry, :attachment, file_id: upload_7.id, missing_on_primary: true)
      create(:geo_upload_registry, :attachment, :never_synced, file_id: upload_8.id)

      expect(subject.count_registry).to eq 8
    end
  end

  describe '#count_synced' do
    it 'counts registries that has been synced' do
      create(:geo_upload_registry, :attachment, :failed, file_id: upload_1.id)
      create(:geo_upload_registry, :attachment, file_id: upload_2.id, missing_on_primary: true)
      create(:geo_upload_registry, :attachment, :never_synced, file_id: upload_3.id)
      create(:geo_upload_registry, :attachment, :failed, file_id: upload_4.id)
      create(:geo_upload_registry, :attachment, file_id: upload_5.id, missing_on_primary: true, retry_at: 1.day.ago)
      create(:geo_upload_registry, :attachment, :failed, file_id: upload_6.id)
      create(:geo_upload_registry, :attachment, file_id: upload_7.id, missing_on_primary: true)
      create(:geo_upload_registry, :attachment, :never_synced, file_id: upload_8.id)

      expect(subject.count_synced).to eq 3
    end
  end

  describe '#count_failed' do
    it 'counts registries that sync has failed' do
      create(:geo_upload_registry, :attachment, :failed, file_id: upload_1.id)
      create(:geo_upload_registry, :attachment, file_id: upload_2.id, missing_on_primary: true)
      create(:geo_upload_registry, :attachment, :never_synced, file_id: upload_3.id)
      create(:geo_upload_registry, :attachment, :failed, file_id: upload_4.id)
      create(:geo_upload_registry, :attachment, file_id: upload_5.id, missing_on_primary: true, retry_at: 1.day.ago)
      create(:geo_upload_registry, :attachment, :failed, file_id: upload_6.id)
      create(:geo_upload_registry, :attachment, file_id: upload_7.id, missing_on_primary: true)
      create(:geo_upload_registry, :attachment, :never_synced, file_id: upload_8.id)

      expect(subject.count_failed).to eq 3
    end
  end

  describe '#count_synced_missing_on_primary' do
    it 'counts registries that have been synced and are missing on the primary, excluding not synced ones' do
      create(:geo_upload_registry, :attachment, :failed, file_id: upload_1.id)
      create(:geo_upload_registry, :attachment, file_id: upload_2.id, missing_on_primary: true)
      create(:geo_upload_registry, :attachment, :never_synced, file_id: upload_3.id)
      create(:geo_upload_registry, :attachment, :failed, file_id: upload_4.id)
      create(:geo_upload_registry, :attachment, file_id: upload_5.id, missing_on_primary: true, retry_at: 1.day.ago)
      create(:geo_upload_registry, :attachment, :failed, file_id: upload_6.id)
      create(:geo_upload_registry, :attachment, file_id: upload_7.id, missing_on_primary: true)
      create(:geo_upload_registry, :attachment, :never_synced, file_id: upload_8.id)

      expect(subject.count_synced_missing_on_primary).to eq 3
    end
  end

  describe '#find_registry_differences' do
    it 'returns untracked IDs as well as tracked IDs that are unused', :aggregate_failures do
      max_id = Upload.maximum(:id)
      create(:geo_upload_registry, :avatar, file_id: upload_1.id)
      create(:geo_upload_registry, :file, file_id: upload_3.id)
      create(:geo_upload_registry, :avatar, file_id: upload_5.id)
      create(:geo_upload_registry, :personal_file, file_id: upload_6.id)
      create(:geo_upload_registry, :avatar, file_id: upload_7.id)
      unused_registry_1 = create(:geo_upload_registry, :attachment, file_id: max_id + 1)
      unused_registry_2 = create(:geo_upload_registry, :personal_file, file_id: max_id + 2)
      range = 1..(max_id + 2)

      untracked, unused = subject.find_registry_differences(range)

      expected_untracked = [
        [upload_2.id, 'avatar'],
        [upload_4.id, 'avatar'],
        [upload_8.id, 'avatar'],
        [upload_9.id, 'avatar']
      ]

      expected_unused = [
        [unused_registry_1.file_id, 'attachment'],
        [unused_registry_2.file_id, 'personal_file']
      ]

      expect(untracked).to match_array(expected_untracked)
      expect(unused).to match_array(expected_unused)
    end
  end

  describe '#find_never_synced_registries' do
    it 'returns registries for uploads that have never been synced' do
      create(:geo_upload_registry, :attachment, :failed, file_id: upload_1.id)
      create(:geo_upload_registry, :attachment, file_id: upload_2.id, missing_on_primary: true)
      registry_upload_3 = create(:geo_upload_registry, :attachment, :never_synced, file_id: upload_3.id)
      create(:geo_upload_registry, :attachment, :failed, file_id: upload_4.id)
      create(:geo_upload_registry, :attachment, file_id: upload_5.id, missing_on_primary: true, retry_at: 1.day.ago)
      create(:geo_upload_registry, :attachment, :failed, file_id: upload_6.id)
      create(:geo_upload_registry, :attachment, file_id: upload_7.id, missing_on_primary: true)
      registry_upload_8 = create(:geo_upload_registry, :attachment, :never_synced, file_id: upload_8.id)

      registries = subject.find_never_synced_registries(batch_size: 10)

      expect(registries).to match_ids(registry_upload_3, registry_upload_8)
    end

    it 'excludes except_ids' do
      create(:geo_upload_registry, :attachment, :failed, file_id: upload_1.id)
      create(:geo_upload_registry, :attachment, file_id: upload_2.id, missing_on_primary: true)
      create(:geo_upload_registry, :attachment, :never_synced, file_id: upload_3.id)
      create(:geo_upload_registry, :attachment, :failed, file_id: upload_4.id)
      create(:geo_upload_registry, :attachment, file_id: upload_5.id, missing_on_primary: true, retry_at: 1.day.ago)
      create(:geo_upload_registry, :attachment, :failed, file_id: upload_6.id)
      create(:geo_upload_registry, :attachment, file_id: upload_7.id, missing_on_primary: true)
      registry_upload_8 = create(:geo_upload_registry, :attachment, :never_synced, file_id: upload_8.id)

      registries = subject.find_never_synced_registries(batch_size: 10, except_ids: [upload_3.id])

      expect(registries).to match_ids(registry_upload_8)
    end
  end

  describe '#find_unsynced' do
    it 'returns registries for uploads that have never been synced' do
      create(:geo_upload_registry, :attachment, :failed, file_id: upload_1.id)
      create(:geo_upload_registry, :attachment, file_id: upload_2.id, missing_on_primary: true)
      registry_upload_3 = create(:geo_upload_registry, :attachment, :never_synced, file_id: upload_3.id)
      create(:geo_upload_registry, :attachment, :failed, file_id: upload_4.id)
      create(:geo_upload_registry, :attachment, file_id: upload_5.id, missing_on_primary: true, retry_at: 1.day.ago)
      create(:geo_upload_registry, :attachment, :failed, file_id: upload_6.id)
      create(:geo_upload_registry, :attachment, file_id: upload_7.id, missing_on_primary: true)
      registry_upload_8 = create(:geo_upload_registry, :attachment, :never_synced, file_id: upload_8.id)

      registries = subject.find_unsynced(batch_size: 10)

      expect(registries).to match_ids(registry_upload_3, registry_upload_8)
    end

    it 'excludes except_ids' do
      create(:geo_upload_registry, :attachment, :failed, file_id: upload_1.id)
      create(:geo_upload_registry, :attachment, file_id: upload_2.id, missing_on_primary: true)
      registry_upload_3 = create(:geo_upload_registry, :attachment, :never_synced, file_id: upload_3.id)
      create(:geo_upload_registry, :attachment, :failed, file_id: upload_4.id)
      create(:geo_upload_registry, :attachment, file_id: upload_5.id, missing_on_primary: true, retry_at: 1.day.ago)
      create(:geo_upload_registry, :attachment, :failed, file_id: upload_6.id)
      create(:geo_upload_registry, :attachment, file_id: upload_7.id, missing_on_primary: true)
      registry_upload_8 = create(:geo_upload_registry, :attachment, :never_synced, file_id: upload_8.id)

      registries = subject.find_unsynced(batch_size: 10, except_ids: [registry_upload_3.file_id])

      expect(registries).to match_ids(registry_upload_8)
    end
  end

  describe '#find_retryable_failed_registries' do
    it 'returns registries for job artifacts that have failed to sync' do
      registry_upload_1 = create(:geo_upload_registry, :attachment, :failed, file_id: upload_1.id)
      create(:geo_upload_registry, :attachment, file_id: upload_2.id, missing_on_primary: true)
      create(:geo_upload_registry, :attachment, :never_synced, file_id: upload_3.id)
      registry_upload_4 = create(:geo_upload_registry, :attachment, :failed, file_id: upload_4.id)
      create(:geo_upload_registry, :attachment, file_id: upload_5.id, missing_on_primary: true, retry_at: 1.day.ago)
      registry_upload_6 = create(:geo_upload_registry, :attachment, :failed, file_id: upload_6.id)
      create(:geo_upload_registry, :attachment, file_id: upload_7.id, missing_on_primary: true)
      create(:geo_upload_registry, :attachment, :never_synced, file_id: upload_8.id)

      registries = subject.find_retryable_failed_registries(batch_size: 10)

      expect(registries).to match_ids(registry_upload_1, registry_upload_4, registry_upload_6)
    end

    it 'excludes except_ids' do
      registry_upload_1 = create(:geo_upload_registry, :attachment, :failed, file_id: upload_1.id)
      create(:geo_upload_registry, :attachment, file_id: upload_2.id, missing_on_primary: true)
      create(:geo_upload_registry, :attachment, :never_synced, file_id: upload_3.id)
      create(:geo_upload_registry, :attachment, :failed, file_id: upload_4.id)
      create(:geo_upload_registry, :attachment, file_id: upload_5.id, missing_on_primary: true, retry_at: 1.day.ago)
      registry_upload_6 = create(:geo_upload_registry, :attachment, :failed, file_id: upload_6.id)
      create(:geo_upload_registry, :attachment, file_id: upload_7.id, missing_on_primary: true)
      create(:geo_upload_registry, :attachment, :never_synced, file_id: upload_8.id)

      registries = subject.find_retryable_failed_registries(batch_size: 10, except_ids: [upload_4.id])

      expect(registries).to match_ids(registry_upload_1, registry_upload_6)
    end
  end

  describe '#find_retryable_synced_missing_on_primary_registries' do
    it 'returns registries for job artifacts that have been synced and are missing on the primary' do
      create(:geo_upload_registry, :attachment, :failed, file_id: upload_1.id)
      registry_upload_2 = create(:geo_upload_registry, :attachment, file_id: upload_2.id, missing_on_primary: true)
      create(:geo_upload_registry, :attachment, :never_synced, file_id: upload_3.id)
      create(:geo_upload_registry, :attachment, :failed, file_id: upload_4.id)
      registry_upload_5 = create(:geo_upload_registry, :attachment, file_id: upload_5.id, missing_on_primary: true, retry_at: 1.day.ago)
      create(:geo_upload_registry, :attachment, :failed, file_id: upload_6.id)
      create(:geo_upload_registry, :attachment, :failed, file_id: upload_7.id, missing_on_primary: true)
      create(:geo_upload_registry, :attachment, :never_synced, file_id: upload_8.id)

      registries = subject.find_retryable_synced_missing_on_primary_registries(batch_size: 10)

      expect(registries).to match_ids(registry_upload_2, registry_upload_5)
    end

    it 'excludes except_ids' do
      create(:geo_upload_registry, :attachment, :failed, file_id: upload_1.id)
      registry_upload_2 = create(:geo_upload_registry, :attachment, file_id: upload_2.id, missing_on_primary: true)
      create(:geo_upload_registry, :attachment, :never_synced, file_id: upload_3.id)
      create(:geo_upload_registry, :attachment, :failed, file_id: upload_4.id)
      create(:geo_upload_registry, :attachment, file_id: upload_5.id, missing_on_primary: true, retry_at: 1.day.ago)
      create(:geo_upload_registry, :attachment, :failed, file_id: upload_6.id)
      create(:geo_upload_registry, :attachment, :failed, file_id: upload_7.id, missing_on_primary: true)
      create(:geo_upload_registry, :attachment, :never_synced, file_id: upload_8.id)

      registries = subject.find_retryable_synced_missing_on_primary_registries(batch_size: 10, except_ids: [upload_5.id])

      expect(registries).to match_ids(registry_upload_2)
    end
  end

  it_behaves_like 'a file registry finder'
end
