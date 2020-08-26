# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Geo::ContainerRepositoryRegistryFinder, :geo do
  let_it_be(:project) { create(:project) }
  let_it_be(:container_repository_1) { create(:container_repository, project: project) }
  let_it_be(:container_repository_2) { create(:container_repository, project: project) }
  let_it_be(:container_repository_3) { create(:container_repository, project: project) }
  let_it_be(:container_repository_4) { create(:container_repository, project: project) }
  let_it_be(:container_repository_5) { create(:container_repository, project: project) }
  let_it_be(:container_repository_6) { create(:container_repository, project: project) }

  before do
    stub_registry_replication_config(enabled: true)
  end

  describe '#registry_count' do
    it 'returns number of container registries' do
      create(:container_repository_registry, :synced, container_repository_id: container_repository_1.id)
      create(:container_repository_registry, :sync_failed, container_repository_id: container_repository_3.id)

      expect(subject.registry_count).to eq(2)
    end
  end

  describe '#synced_count' do
    it 'returns only synced registry' do
      create(:container_repository_registry, :synced, container_repository_id: container_repository_1.id)
      create(:container_repository_registry, :sync_failed, container_repository_id: container_repository_3.id)

      expect(subject.synced_count).to eq(1)
    end
  end

  describe '#failed_count' do
    it 'returns only failed registry' do
      create(:container_repository_registry, :synced, container_repository_id: container_repository_1.id)
      create(:container_repository_registry, :sync_failed, container_repository_id: container_repository_3.id)

      expect(subject.failed_count).to eq(1)
    end
  end

  describe '#find_unsynced_registries' do
    let_it_be(:registry_container_registry_1) { create(:container_repository_registry, :synced, container_repository_id: container_repository_1.id) }
    let_it_be(:registry_container_registry_2) { create(:container_repository_registry, :sync_failed, container_repository_id: container_repository_2.id) }
    let_it_be(:registry_container_registry_3) { create(:container_repository_registry, container_repository_id: container_repository_3.id, last_synced_at: nil) }
    let_it_be(:registry_container_registry_4) { create(:container_repository_registry, container_repository_id: container_repository_4.id, last_synced_at: 3.days.ago, retry_at: 2.days.ago) }
    let_it_be(:registry_container_registry_5) { create(:container_repository_registry, container_repository_id: container_repository_5.id, last_synced_at: 6.days.ago) }
    let_it_be(:registry_container_registry_6) { create(:container_repository_registry, container_repository_id: container_repository_6.id, last_synced_at: nil) }

    it 'returns registries for projects that have never been synced' do
      registries = subject.find_unsynced_registries(batch_size: 10)

      expect(registries).to match_ids(registry_container_registry_3, registry_container_registry_6)
    end

    it 'excludes except_ids' do
      registries = subject.find_unsynced_registries(batch_size: 10, except_ids: [container_repository_3.id])

      expect(registries).to match_ids(registry_container_registry_6)
    end
  end

  describe '#find_failed_registries' do
    let_it_be(:registry_container_registry_1) { create(:container_repository_registry, :synced, container_repository_id: container_repository_1.id) }
    let_it_be(:registry_container_registry_2) { create(:container_repository_registry, :sync_started, container_repository_id: container_repository_2.id) }
    let_it_be(:registry_container_registry_3) { create(:container_repository_registry, state: :failed, container_repository_id: container_repository_3.id, last_synced_at: nil) }
    let_it_be(:registry_container_registry_4) { create(:container_repository_registry, state: :failed, container_repository_id: container_repository_4.id, last_synced_at: 3.days.ago, retry_at: 2.days.ago) }
    let_it_be(:registry_container_registry_5) { create(:container_repository_registry, state: :failed, container_repository_id: container_repository_5.id, last_synced_at: 6.days.ago) }
    let_it_be(:registry_container_registry_6) { create(:container_repository_registry, state: :failed, container_repository_id: container_repository_6.id, last_synced_at: nil) }

    it 'returns registries for projects that have been recently updated' do
      registries = subject.find_failed_registries(batch_size: 10)

      expect(registries).to match_ids(registry_container_registry_3, registry_container_registry_4, registry_container_registry_5, registry_container_registry_6)
    end

    it 'excludes except_ids' do
      registries = subject.find_failed_registries(batch_size: 10, except_ids: [container_repository_4.id, container_repository_5.id, container_repository_6.id])

      expect(registries).to match_ids(registry_container_registry_3)
    end
  end
end
