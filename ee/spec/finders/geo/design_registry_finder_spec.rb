# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Geo::DesignRegistryFinder, :geo do
  include ::EE::GeoHelpers

  let(:secondary) { create(:geo_node) }
  let(:project_1) { create(:project) }
  let(:project_2) { create(:project) }
  let(:project_3) { create(:project) }
  let(:project_4) { create(:project) }
  let(:project_5) { create(:project) }
  let(:project_6) { create(:project) }

  subject { described_class.new(current_node_id: secondary.id) }

  context 'when geo_design_registry_ssot_sync is disabled', :geo_fdw do
    let!(:failed_registry) { create(:geo_design_registry, :sync_failed) }
    let!(:synced_registry) { create(:geo_design_registry, :synced) }

    before do
      stub_feature_flags(geo_design_registry_ssot_sync: false)
    end

    describe '#count_syncable' do
      it 'returns number of design repositories' do
        # One more design for the same project to assert absence of duplicates
        create(:design, project: synced_registry.project)

        expect(subject.count_syncable).to eq(2)
      end
    end

    describe '#count_synced' do
      it 'returns only synced registry' do
        expect(subject.count_synced).to eq(1)
      end
    end

    describe '#count_failed' do
      it 'returns only failed registry' do
        expect(subject.count_failed).to eq(1)
      end
    end

    describe '#count_registry' do
      it 'returns number of all registries' do
        expect(subject.count_registry).to eq(2)
      end
    end

    context 'selective sync' do
      let(:synced_group) { create(:group) }
      let(:unsynced_group) { create(:group) }
      let(:synced_project) { create(:project, group: synced_group) }
      let(:unsynced_project) { create(:project, :broken_storage, group: unsynced_group) }
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

  context 'when geo_design_registry_ssot_sync is enabled' do
    let!(:registry_project_1) { create(:geo_design_registry, :synced, project_id: project_1.id) }
    let!(:registry_project_2) { create(:geo_design_registry, :sync_failed, project_id: project_2.id) }
    let!(:registry_project_3) { create(:geo_design_registry, project_id: project_3.id, last_synced_at: nil) }
    let!(:registry_project_4) { create(:geo_design_registry, project_id: project_4.id, last_synced_at: 3.days.ago, retry_at: 2.days.ago) }
    let!(:registry_project_5) { create(:geo_design_registry, project_id: project_5.id, last_synced_at: 6.days.ago) }
    let!(:registry_project_6) { create(:geo_design_registry, project_id: project_6.id, last_synced_at: nil) }

    before do
      stub_feature_flags(geo_design_registry_ssot_sync: true)
    end

    describe '#count_syncable' do
      it 'returns number of design repositories' do
        # One more design for the same project to assert absence of duplicates
        create(:design, project: project_1)

        result = subject.count_syncable

        expect(result).to eq(6)
      end
    end

    describe '#count_synced' do
      it 'returns only synced registry' do
        expect(subject.count_synced).to eq(1)
      end
    end

    describe '#count_failed' do
      it 'returns only failed registry' do
        expect(subject.count_failed).to eq(1)
      end
    end

    describe '#count_registry' do
      it 'returns number of all registries' do
        expect(subject.count_registry).to eq(6)
      end
    end
  end

  describe '#find_registry_differences' do
    let_it_be(:secondary) { create(:geo_node) }
    let_it_be(:synced_group) { create(:group) }
    let_it_be(:nested_group) { create(:group, parent: synced_group) }
    let_it_be(:project_1) { create(:project, group: synced_group) }
    let_it_be(:project_2) { create(:project, group: nested_group) }
    let_it_be(:project_3) { create(:project) }
    let_it_be(:project_4) { create(:project) }
    let_it_be(:project_5) { create(:project, :broken_storage) }
    let_it_be(:project_6) { create(:project, :broken_storage) }
    let_it_be(:project_7) { create(:project) }

    before_all do
      create(:design, project: project_1)
      create(:design, project: project_2)
      create(:design, project: project_3)
      create(:design, project: project_4)
      create(:design, project: project_5)
      create(:design, project: project_6)
    end

    before do
      stub_current_geo_node(secondary)
    end

    context 'untracked IDs' do
      before do
        create(:geo_design_registry, project_id: project_1.id)
        create(:geo_design_registry, :sync_failed, project_id: project_3.id)
        create(:geo_design_registry, project_id: project_5.id)
      end

      it 'includes project IDs without an entry on the tracking database' do
        range = Project.minimum(:id)..Project.maximum(:id)

        untracked_ids, _ = subject.find_registry_differences(range)

        expect(untracked_ids).to match_array([project_2.id, project_4.id, project_6.id])
      end

      it 'excludes projects outside the ID range' do
        untracked_ids, _ = subject.find_registry_differences(project_4.id..project_6.id)

        expect(untracked_ids).to match_array([project_4.id, project_6.id])
      end

      it 'excludes projects without designs' do
        range = Project.minimum(:id)..Project.maximum(:id)

        untracked_ids, _ = subject.find_registry_differences(range)

        expect(untracked_ids).not_to include([project_7])
      end

      context 'with selective sync by namespace' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'namespaces', namespaces: [synced_group]) }

        it 'excludes project IDs that are not in selectively synced projects' do
          range = Project.minimum(:id)..Project.maximum(:id)

          untracked_ids, _ = subject.find_registry_differences(range)

          expect(untracked_ids).to match_array([project_2.id])
        end
      end

      context 'with selective sync by shard' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'shards', selective_sync_shards: ['broken']) }

        it 'excludes project IDs that are not in selectively synced projects' do
          range = Project.minimum(:id)..Project.maximum(:id)

          untracked_ids, _ = subject.find_registry_differences(range)

          expect(untracked_ids).to match_array([project_6.id])
        end
      end
    end

    context 'unused tracked IDs' do
      context 'with an orphaned registry' do
        let!(:orphaned) { create(:geo_design_registry, project_id: project_1.id) }

        before do
          project_1.delete
        end

        it 'includes tracked IDs that do not exist in the model table' do
          range = project_1.id..project_1.id

          _, unused_tracked_ids = subject.find_registry_differences(range)

          expect(unused_tracked_ids).to match_array([project_1.id])
        end

        it 'excludes IDs outside the ID range' do
          range = (project_1.id + 1)..Project.maximum(:id)

          _, unused_tracked_ids = subject.find_registry_differences(range)

          expect(unused_tracked_ids).to be_empty
        end
      end

      context 'with selective sync by namespace' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'namespaces', namespaces: [synced_group]) }

        context 'with a tracked project' do
          context 'excluded from selective sync' do
            let!(:registry_entry) { create(:geo_design_registry, project_id: project_3.id) }

            it 'includes tracked project IDs that exist but are not in a selectively synced project' do
              range = project_3.id..project_3.id

              _, unused_tracked_ids = subject.find_registry_differences(range)

              expect(unused_tracked_ids).to match_array([project_3.id])
            end
          end

          context 'included in selective sync' do
            let!(:registry_entry) { create(:geo_design_registry, project_id: project_1.id) }

            it 'excludes tracked project IDs that are in selectively synced projects' do
              range = project_1.id..project_1.id

              _, unused_tracked_ids = subject.find_registry_differences(range)

              expect(unused_tracked_ids).to be_empty
            end
          end
        end
      end

      context 'with selective sync by shard' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'shards', selective_sync_shards: ['broken']) }

        context 'with a tracked project' do
          let!(:registry_entry) { create(:geo_design_registry, project_id: project_1.id) }

          context 'excluded from selective sync' do
            it 'includes tracked project IDs that exist but are not in a selectively synced project' do
              range = project_1.id..project_1.id

              _, unused_tracked_ids = subject.find_registry_differences(range)

              expect(unused_tracked_ids).to match_array([project_1.id])
            end
          end

          context 'included in selective sync' do
            let!(:registry_entry) { create(:geo_design_registry, project_id: project_5.id) }

            it 'excludes tracked project IDs that are in selectively synced projects' do
              range = project_5.id..project_5.id

              _, unused_tracked_ids = subject.find_registry_differences(range)

              expect(unused_tracked_ids).to be_empty
            end
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
