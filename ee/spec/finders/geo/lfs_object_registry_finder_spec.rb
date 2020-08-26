# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::LfsObjectRegistryFinder, :geo do
  before do
    stub_lfs_object_storage
  end

  let_it_be(:lfs_object_1) { create(:lfs_object) }
  let_it_be(:lfs_object_2) { create(:lfs_object) }
  let_it_be(:lfs_object_3) { create(:lfs_object) }
  let_it_be(:lfs_object_4) { create(:lfs_object) }
  let_it_be(:lfs_object_5) { create(:lfs_object) }
  let!(:lfs_object_remote_1) { create(:lfs_object, :object_storage) }
  let!(:lfs_object_remote_2) { create(:lfs_object, :object_storage) }
  let!(:lfs_object_remote_3) { create(:lfs_object, :object_storage) }

  let_it_be(:registry_lfs_object_1) { create(:geo_lfs_object_registry, :failed, lfs_object_id: lfs_object_1.id) }
  let_it_be(:registry_lfs_object_2) { create(:geo_lfs_object_registry, lfs_object_id: lfs_object_2.id, missing_on_primary: true) }
  let_it_be(:registry_lfs_object_3) { create(:geo_lfs_object_registry, :never_synced, lfs_object_id: lfs_object_3.id) }
  let_it_be(:registry_lfs_object_4) { create(:geo_lfs_object_registry, :failed, lfs_object_id: lfs_object_4.id) }
  let_it_be(:registry_lfs_object_5) { create(:geo_lfs_object_registry, lfs_object_id: lfs_object_5.id, missing_on_primary: true, retry_at: 1.day.ago) }
  let!(:registry_lfs_object_remote_1) { create(:geo_lfs_object_registry, :failed, lfs_object_id: lfs_object_remote_1.id) }
  let!(:registry_lfs_object_remote_2) { create(:geo_lfs_object_registry, :failed, lfs_object_id: lfs_object_remote_2.id, missing_on_primary: true) }
  let!(:registry_lfs_object_remote_3) { create(:geo_lfs_object_registry, :never_synced, lfs_object_id: lfs_object_remote_3.id) }

  describe '#registry_count' do
    it 'counts registries for LFS objects' do
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
    it 'returns registries for LFS objects that have never been synced' do
      registries = subject.find_unsynced_registries(batch_size: 10)

      expect(registries).to match_ids(registry_lfs_object_3, registry_lfs_object_remote_3)
    end

    it 'excludes except_ids' do
      registries = subject.find_unsynced_registries(batch_size: 10, except_ids: [lfs_object_3.id])

      expect(registries).to match_ids(registry_lfs_object_remote_3)
    end
  end

  describe '#find_failed_registries' do
    it 'returns registries for LFS objects that have failed to sync' do
      registries = subject.find_failed_registries(batch_size: 10)

      expect(registries).to match_ids(registry_lfs_object_1, registry_lfs_object_4, registry_lfs_object_remote_1, registry_lfs_object_remote_2)
    end

    it 'excludes except_ids' do
      registries = subject.find_failed_registries(batch_size: 10, except_ids: [lfs_object_4.id, lfs_object_remote_2.id])

      expect(registries).to match_ids(registry_lfs_object_1, registry_lfs_object_remote_1)
    end
  end

  describe '#find_retryable_synced_missing_on_primary_registries' do
    it 'returns registries for LFS objects that have been synced and are missing on the primary' do
      registries = subject.find_retryable_synced_missing_on_primary_registries(batch_size: 10)

      expect(registries).to match_ids(registry_lfs_object_2, registry_lfs_object_5)
    end

    it 'excludes except_ids' do
      registries = subject.find_retryable_synced_missing_on_primary_registries(batch_size: 10, except_ids: [lfs_object_5.id])

      expect(registries).to match_ids(registry_lfs_object_2)
    end
  end

  it_behaves_like 'a file registry finder'
end
