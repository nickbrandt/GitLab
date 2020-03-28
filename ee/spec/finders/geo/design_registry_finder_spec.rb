# frozen_string_literal: true
require 'spec_helper'

describe Geo::DesignRegistryFinder, :geo, :geo_fdw do
  include ::EE::GeoHelpers

  let!(:secondary) { create(:geo_node) }
  let!(:failed_registry) { create(:geo_design_registry, :sync_failed) }
  let!(:synced_registry) { create(:geo_design_registry, :synced) }

  let(:synced_group) { create(:group) }
  let(:unsynced_group) { create(:group) }
  let(:synced_project) { create(:project, group: synced_group) }
  let(:unsynced_project) { create(:project, :broken_storage, group: unsynced_group) }

  subject { described_class.new(current_node_id: secondary.id) }

  before do
    stub_current_geo_node(secondary)
  end

  context 'count all the things' do
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
end
