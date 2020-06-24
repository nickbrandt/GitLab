# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::ProjectRegistryFinder, :geo do
  let_it_be(:project_1) { create(:project) }
  let_it_be(:project_2) { create(:project) }
  let_it_be(:project_3) { create(:project) }
  let_it_be(:project_4) { create(:project) }
  let_it_be(:project_5) { create(:project) }
  let_it_be(:project_6) { create(:project) }

  let_it_be(:registry_project_1) { create(:geo_project_registry, :synced, project_id: project_1.id) }
  let_it_be(:registry_project_2) { create(:geo_project_registry, :sync_failed, project_id: project_2.id) }
  let_it_be(:registry_project_3) { create(:geo_project_registry, project_id: project_3.id) }
  let_it_be(:registry_project_4) { create(:geo_project_registry, :repository_dirty, project_id: project_4.id, last_repository_synced_at: 2.days.ago) }
  let_it_be(:registry_project_5) { create(:geo_project_registry, :wiki_dirty, project_id: project_5.id, last_repository_synced_at: 5.days.ago) }
  let_it_be(:registry_project_6) { create(:geo_project_registry, project_id: project_6.id) }

  describe '#find_never_synced_registries' do
    it 'returns registries for projects that have never been synced' do
      registries = subject.find_never_synced_registries(batch_size: 10)

      expect(registries).to match_ids(registry_project_3, registry_project_6)
    end

    it 'excludes except_ids' do
      registries = subject.find_never_synced_registries(batch_size: 10, except_ids: [project_3.id])

      expect(registries).to match_ids(registry_project_6)
    end
  end

  describe '#find_retryable_dirty_registries' do
    it 'returns registries for projects that have been recently updated or that have never been synced' do
      registries = subject.find_retryable_dirty_registries(batch_size: 10)

      expect(registries).to match_ids(registry_project_2, registry_project_3, registry_project_4, registry_project_5, registry_project_6)
    end

    it 'excludes except_ids' do
      registries = subject.find_retryable_dirty_registries(batch_size: 10, except_ids: [project_4.id, project_5.id, project_6.id])

      expect(registries).to match_ids(registry_project_2, registry_project_3)
    end
  end
end
