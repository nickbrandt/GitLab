# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Geo::DesignRegistryFinder, :geo do
  let_it_be(:group) { create(:group) }
  let_it_be(:project_1) { create(:project, group: group) }
  let_it_be(:project_2) { create(:project, group: group) }
  let_it_be(:project_3) { create(:project, group: group) }
  let_it_be(:project_4) { create(:project, group: group) }
  let_it_be(:project_5) { create(:project, :broken_storage, group: group) }
  let_it_be(:project_6) { create(:project, :broken_storage, group: group) }
  let_it_be(:project_7) { create(:project, group: group) }

  let_it_be(:registry_project_1) { create(:geo_design_registry, :synced, project_id: project_1.id) }
  let_it_be(:registry_project_2) { create(:geo_design_registry, :sync_failed, project_id: project_2.id) }
  let_it_be(:registry_project_3) { create(:geo_design_registry, project_id: project_3.id, last_synced_at: nil) }
  let_it_be(:registry_project_4) { create(:geo_design_registry, project_id: project_4.id, last_synced_at: 3.days.ago, retry_at: 2.days.ago) }
  let_it_be(:registry_project_5) { create(:geo_design_registry, project_id: project_5.id, last_synced_at: 6.days.ago) }
  let_it_be(:registry_project_6) { create(:geo_design_registry, project_id: project_6.id, last_synced_at: nil) }

  describe '#registry_count' do
    it 'returns number of desgin registries' do
      expect(subject.registry_count).to eq(6)
    end
  end

  describe '#synced_count' do
    it 'returns number of synced registries' do
      expect(subject.synced_count).to eq(1)
    end
  end

  describe '#failed_count' do
    it 'returns number of failed registries' do
      expect(subject.failed_count).to eq(1)
    end
  end

  describe '#find_unsynced_registries' do
    it 'returns registries for projects that have never been synced' do
      registries = subject.find_unsynced_registries(batch_size: 10)

      expect(registries).to match_ids(registry_project_3, registry_project_6)
    end

    it 'excludes except_ids' do
      registries = subject.find_unsynced_registries(batch_size: 10, except_ids: [project_3.id])

      expect(registries).to match_ids(registry_project_6)
    end
  end

  describe '#find_failed_registries' do
    it 'returns registries for projects that have been recently updated' do
      registries = subject.find_failed_registries(batch_size: 10)

      expect(registries).to match_ids(registry_project_2, registry_project_3, registry_project_4, registry_project_5, registry_project_6)
    end

    it 'excludes except_ids' do
      registries = subject.find_failed_registries(batch_size: 10, except_ids: [project_4.id, project_5.id, project_6.id])

      expect(registries).to match_ids(registry_project_2, registry_project_3)
    end
  end
end
