# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::AttachmentRegistryFinder, :geo do
  let_it_be(:project) { create(:project) }
  let_it_be(:upload_1) { create(:upload, model: project) }
  let_it_be(:upload_2) { create(:upload, model: project) }
  let_it_be(:upload_3) { create(:upload, :issuable_upload, model: project) }
  let_it_be(:upload_4) { create(:upload, model: project) }
  let_it_be(:upload_5) { create(:upload, model: project) }
  let_it_be(:upload_6) { create(:upload, :personal_snippet_upload) }
  let_it_be(:upload_7) { create(:upload, :object_storage, model: project) }
  let_it_be(:upload_8) { create(:upload, :object_storage, model: project) }
  let_it_be(:upload_9) { create(:upload, :object_storage, model: project) }

  let_it_be(:registry_upload_1) { create(:geo_upload_registry, :attachment, :failed, file_id: upload_1.id) }
  let_it_be(:registry_upload_2) { create(:geo_upload_registry, :attachment, file_id: upload_2.id, missing_on_primary: true) }
  let_it_be(:registry_upload_3) { create(:geo_upload_registry, :attachment, :never_synced, file_id: upload_3.id) }
  let_it_be(:registry_upload_4) { create(:geo_upload_registry, :attachment, :failed, file_id: upload_4.id) }
  let_it_be(:registry_upload_5) { create(:geo_upload_registry, :attachment, file_id: upload_5.id, missing_on_primary: true, retry_at: 1.day.ago) }
  let_it_be(:registry_upload_6) { create(:geo_upload_registry, :attachment, :failed, file_id: upload_6.id) }
  let_it_be(:registry_upload_7) { create(:geo_upload_registry, :attachment, :failed, file_id: upload_7.id, missing_on_primary: true) }
  let_it_be(:registry_upload_8) { create(:geo_upload_registry, :attachment, :never_synced, file_id: upload_8.id) }

  describe '#registry_count' do
    it 'counts registries for uploads' do
      expect(subject.registry_count).to eq 8
    end
  end

  describe '#synced_count' do
    it 'counts registries that has been synced' do
      expect(subject.synced_count).to eq 2
    end
  end

  describe '#failed_count' do
    it 'counts registries that sync has failed' do
      expect(subject.failed_count).to eq 4
    end
  end

  describe '#synced_missing_on_primary_count' do
    it 'counts registries that have been synced and are missing on the primary, excluding not synced ones' do
      expect(subject.synced_missing_on_primary_count).to eq 2
    end
  end

  describe '#find_unsynced_registries' do
    it 'returns registries for uploads that have never been synced' do
      registries = subject.find_unsynced_registries(batch_size: 10)

      expect(registries).to match_ids(registry_upload_3, registry_upload_8)
    end

    it 'excludes except_ids' do
      registries = subject.find_unsynced_registries(batch_size: 10, except_ids: [upload_3.id])

      expect(registries).to match_ids(registry_upload_8)
    end
  end

  describe '#find_failed_registries' do
    it 'returns registries for job artifacts that have failed to sync' do
      registries = subject.find_failed_registries(batch_size: 10)

      expect(registries).to match_ids(registry_upload_1, registry_upload_4, registry_upload_6, registry_upload_7)
    end

    it 'excludes except_ids' do
      registries = subject.find_failed_registries(batch_size: 10, except_ids: [upload_4.id, upload_7.id])

      expect(registries).to match_ids(registry_upload_1, registry_upload_6)
    end
  end

  describe '#find_retryable_synced_missing_on_primary_registries' do
    it 'returns registries for job artifacts that have been synced and are missing on the primary' do
      registries = subject.find_retryable_synced_missing_on_primary_registries(batch_size: 10)

      expect(registries).to match_ids(registry_upload_2, registry_upload_5)
    end

    it 'excludes except_ids' do
      registries = subject.find_retryable_synced_missing_on_primary_registries(batch_size: 10, except_ids: [upload_5.id])

      expect(registries).to match_ids(registry_upload_2)
    end
  end

  it_behaves_like 'a file registry finder'
end
