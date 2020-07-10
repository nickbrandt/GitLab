# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Geo::DesignRegistryFinder, :geo, :geo_fdw do
  let!(:secondary) { create(:geo_node) }
  let!(:project_1) { create(:project) }
  let!(:project_2) { create(:project) }
  let!(:project_3) { create(:project) }
  let!(:project_4) { create(:project) }
  let!(:project_5) { create(:project) }
  let!(:project_6) { create(:project) }

  subject { described_class.new(current_node_id: secondary.id) }

  context 'count all the things' do
    let!(:failed_registry) { create(:geo_design_registry, :sync_failed) }
    let!(:synced_registry) { create(:geo_design_registry, :synced) }

    let(:synced_group) { create(:group) }
    let(:unsynced_group) { create(:group) }
    let(:synced_project) { create(:project, group: synced_group) }
    let(:unsynced_project) { create(:project, :broken_storage, group: unsynced_group) }

    describe '#count_syncable' do
      it 'returns number of design repositories' do
        # One more design for the same project to assert absence of duplicates
        create(:design, project: synced_registry.project)

        result = subject.count_syncable

        expect(result).to eq(2)
      end
    end

    describe '#count_synced' do
      it 'returns only synced registry' do
        result = subject.count_synced

        expect(result).to eq(1)
      end
    end

    describe '#count_failed' do
      it 'returns only failed registry' do
        result = subject.count_failed

        expect(result).to eq(1)
      end
    end

    describe '#count_registry' do
      it 'returns number of all registries' do
        result = subject.count_registry

        expect(result).to eq(2)
      end
    end

    context 'selective sync' do
      let(:unsynced_project2) { create(:project, group: unsynced_group) }
      let(:synced_project2) { create(:project, group: synced_group) }

      before do
        create(:geo_design_registry, :synced, project: synced_project)
        create(:geo_design_registry, :sync_failed, project: synced_project2)
        create(:geo_design_registry, :synced, project: unsynced_project)
        create(:geo_design_registry, :sync_failed, project: unsynced_project2)

        secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])
      end

      context 'count all the things' do
        describe '#count_syncable' do
          it 'returns number of design repositories' do
            result = subject.count_syncable

            expect(result).to eq(2)
          end
        end

        describe '#count_synced' do
          it 'returns only synced registry' do
            result = subject.count_synced

            expect(result).to eq(1)
          end
        end

        describe '#count_failed' do
          it 'returns only failed registry' do
            result = subject.count_failed

            expect(result).to eq(1)
          end
        end

        describe '#count_registry' do
          it 'returns number of all registries' do
            result = subject.count_registry

            expect(result).to eq(2)
          end
        end
      end
    end
  end

  describe '#find_never_synced_registries' do
    let!(:registry_project_1) { create(:geo_design_registry, :synced, project_id: project_1.id) }
    let!(:registry_project_2) { create(:geo_design_registry, :sync_failed, project_id: project_2.id) }
    let!(:registry_project_3) { create(:geo_design_registry, project_id: project_3.id, last_synced_at: nil) }
    let!(:registry_project_4) { create(:geo_design_registry, project_id: project_4.id, last_synced_at: 3.days.ago, retry_at: 2.days.ago) }
    let!(:registry_project_5) { create(:geo_design_registry, project_id: project_5.id, last_synced_at: 6.days.ago) }
    let!(:registry_project_6) { create(:geo_design_registry, project_id: project_6.id, last_synced_at: nil) }

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
    let!(:registry_project_1) { create(:geo_design_registry, :synced, project_id: project_1.id) }
    let!(:registry_project_2) { create(:geo_design_registry, :sync_failed, project_id: project_2.id) }
    let!(:registry_project_3) { create(:geo_design_registry, project_id: project_3.id, last_synced_at: nil) }
    let!(:registry_project_4) { create(:geo_design_registry, project_id: project_4.id, last_synced_at: 3.days.ago, retry_at: 2.days.ago) }
    let!(:registry_project_5) { create(:geo_design_registry, project_id: project_5.id, last_synced_at: 6.days.ago) }
    let!(:registry_project_6) { create(:geo_design_registry, project_id: project_6.id, last_synced_at: nil) }

    it 'returns registries for projects that have been recently updated' do
      registries = subject.find_retryable_dirty_registries(batch_size: 10)

      expect(registries).to match_ids(registry_project_2, registry_project_3, registry_project_4, registry_project_5, registry_project_6)
    end

    it 'excludes except_ids' do
      registries = subject.find_retryable_dirty_registries(batch_size: 10, except_ids: [project_4.id, project_5.id, project_6.id])

      expect(registries).to match_ids(registry_project_2, registry_project_3)
    end
  end
end
