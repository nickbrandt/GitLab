# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Geo::ContainerRepositoryRegistryFinder, :geo do
  include ::EE::GeoHelpers

  let_it_be(:secondary) { create(:geo_node) }
  let_it_be(:synced_group) { create(:group) }
  let_it_be(:nested_group) { create(:group, parent: synced_group) }
  let_it_be(:project_synced_group) { create(:project, group: synced_group) }
  let_it_be(:project_nested_group) { create(:project, group: nested_group) }
  let_it_be(:project_broken_storage) { create(:project, :broken_storage) }
  let_it_be(:container_repository_1) { create(:container_repository, project: project_synced_group) }
  let_it_be(:container_repository_2) { create(:container_repository, project: project_nested_group) }
  let_it_be(:container_repository_3) { create(:container_repository) }
  let_it_be(:container_repository_4) { create(:container_repository) }
  let_it_be(:container_repository_5) { create(:container_repository, project: project_broken_storage) }
  let_it_be(:container_repository_6) { create(:container_repository, project: project_broken_storage) }

  subject { described_class.new(current_node_id: secondary.id) }

  before do
    stub_current_geo_node(secondary)
    stub_registry_replication_config(enabled: true)
  end

  describe '#count_syncable' do
    it 'returns number of container repositories' do
      expect(subject.count_syncable).to eq(6)
    end
  end

  describe '#count_synced' do
    it 'returns only synced registry' do
      create(:container_repository_registry, :synced, container_repository_id: container_repository_1.id)
      create(:container_repository_registry, :sync_failed, container_repository_id: container_repository_3.id)

      expect(subject.count_synced).to eq(1)
    end
  end

  describe '#count_failed' do
    it 'returns only failed registry' do
      create(:container_repository_registry, :synced, container_repository_id: container_repository_1.id)
      create(:container_repository_registry, :sync_failed, container_repository_id: container_repository_3.id)

      expect(subject.count_failed).to eq(1)
    end
  end

  describe '#count_registry' do
    it 'returns number of all registries' do
      create(:container_repository_registry, :synced, container_repository_id: container_repository_1.id)
      create(:container_repository_registry, :sync_failed, container_repository_id: container_repository_3.id)

      expect(subject.count_registry).to eq(2)
    end
  end

  describe '#find_registry_differences' do
    context 'untracked IDs' do
      before do
        create(:container_repository_registry, container_repository_id: container_repository_1.id)
        create(:container_repository_registry, :sync_failed, container_repository_id: container_repository_3.id)
        create(:container_repository_registry, container_repository_id: container_repository_5.id)
      end

      it 'includes container registries IDs without an entry on the tracking database' do
        range = ContainerRepository.minimum(:id)..ContainerRepository.maximum(:id)

        untracked_ids, _ = subject.find_registry_differences(range)

        expect(untracked_ids).to match_array([container_repository_2.id, container_repository_4.id, container_repository_6.id])
      end

      it 'excludes container registries outside the ID range' do
        untracked_ids, _ = subject.find_registry_differences(container_repository_4.id..container_repository_6.id)

        expect(untracked_ids).to match_array([container_repository_4.id, container_repository_6.id])
      end

      context 'with selective sync by namespace' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'namespaces', namespaces: [synced_group]) }

        it 'excludes container_registry IDs that projects are not in the selected namespaces' do
          range = ContainerRepository.minimum(:id)..ContainerRepository.maximum(:id)

          untracked_ids, _ = subject.find_registry_differences(range)

          expect(untracked_ids).to match_array([container_repository_2.id])
        end
      end

      context 'with selective sync by shard' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'shards', selective_sync_shards: ['broken']) }

        it 'excludes container_registry IDs that projects are not in the selected shards' do
          range = ContainerRepository.minimum(:id)..ContainerRepository.maximum(:id)

          untracked_ids, _ = subject.find_registry_differences(range)

          expect(untracked_ids).to match_array([container_repository_6.id])
        end
      end
    end

    context 'unused tracked IDs' do
      context 'with an orphaned registry' do
        let!(:orphaned) { create(:container_repository_registry, container_repository_id: container_repository_1.id) }

        before do
          container_repository_1.delete
        end

        it 'includes tracked IDs that do not exist in the model table' do
          range = container_repository_1.id..container_repository_1.id

          _, unused_tracked_ids = subject.find_registry_differences(range)

          expect(unused_tracked_ids).to match_array([container_repository_1.id])
        end

        it 'excludes IDs outside the ID range' do
          range = (container_repository_1.id + 1)..ContainerRepository.maximum(:id)

          _, unused_tracked_ids = subject.find_registry_differences(range)

          expect(unused_tracked_ids).to be_empty
        end
      end

      context 'with selective sync by namespace' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'namespaces', namespaces: [synced_group]) }

        context 'with a tracked container_registry' do
          context 'excluded from selective sync' do
            let!(:registry_entry) { create(:container_repository_registry, container_repository_id: container_repository_3.id) }

            it 'includes tracked container_registry IDs that exist but are not in a selectively synced project' do
              range = container_repository_3.id..container_repository_3.id

              _, unused_tracked_ids = subject.find_registry_differences(range)

              expect(unused_tracked_ids).to match_array([container_repository_3.id])
            end
          end

          context 'included in selective sync' do
            let!(:registry_entry) { create(:container_repository_registry, container_repository_id: container_repository_1.id) }

            it 'excludes tracked container_registry IDs that are in selectively synced projects' do
              range = container_repository_1.id..container_repository_1.id

              _, unused_tracked_ids = subject.find_registry_differences(range)

              expect(unused_tracked_ids).to be_empty
            end
          end
        end
      end

      context 'with selective sync by shard' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'shards', selective_sync_shards: ['broken']) }

        context 'with a tracked container_registry' do
          let!(:registry_entry) { create(:container_repository_registry, container_repository_id: container_repository_1.id) }

          context 'excluded from selective sync' do
            it 'includes tracked container_registry IDs that exist but are not in a selectively synced project' do
              range = container_repository_1.id..container_repository_1.id

              _, unused_tracked_ids = subject.find_registry_differences(range)

              expect(unused_tracked_ids).to match_array([container_repository_1.id])
            end
          end

          context 'included in selective sync' do
            let!(:registry_entry) { create(:container_repository_registry, container_repository_id: container_repository_5.id) }

            it 'excludes tracked container_registry IDs that are in selectively synced projects' do
              range = container_repository_5.id..container_repository_5.id

              _, unused_tracked_ids = subject.find_registry_differences(range)

              expect(unused_tracked_ids).to be_empty
            end
          end
        end
      end
    end
  end

  describe '#find_never_synced_registries' do
    let_it_be(:registry_container_registry_1) { create(:container_repository_registry, :synced, container_repository_id: container_repository_1.id) }
    let_it_be(:registry_container_registry_2) { create(:container_repository_registry, :sync_failed, container_repository_id: container_repository_2.id) }
    let_it_be(:registry_container_registry_3) { create(:container_repository_registry, container_repository_id: container_repository_3.id, last_synced_at: nil) }
    let_it_be(:registry_container_registry_4) { create(:container_repository_registry, container_repository_id: container_repository_4.id, last_synced_at: 3.days.ago, retry_at: 2.days.ago) }
    let_it_be(:registry_container_registry_5) { create(:container_repository_registry, container_repository_id: container_repository_5.id, last_synced_at: 6.days.ago) }
    let_it_be(:registry_container_registry_6) { create(:container_repository_registry, container_repository_id: container_repository_6.id, last_synced_at: nil) }

    it 'returns registries for projects that have never been synced' do
      registries = subject.find_never_synced_registries(batch_size: 10)

      expect(registries).to match_ids(registry_container_registry_3, registry_container_registry_6)
    end

    it 'excludes except_ids' do
      registries = subject.find_never_synced_registries(batch_size: 10, except_ids: [container_repository_3.id])

      expect(registries).to match_ids(registry_container_registry_6)
    end
  end

  describe '#find_retryable_dirty_registries' do
    let_it_be(:registry_container_registry_1) { create(:container_repository_registry, :synced, container_repository_id: container_repository_1.id) }
    let_it_be(:registry_container_registry_2) { create(:container_repository_registry, :sync_started, container_repository_id: container_repository_2.id) }
    let_it_be(:registry_container_registry_3) { create(:container_repository_registry, state: :failed, container_repository_id: container_repository_3.id, last_synced_at: nil) }
    let_it_be(:registry_container_registry_4) { create(:container_repository_registry, state: :failed, container_repository_id: container_repository_4.id, last_synced_at: 3.days.ago, retry_at: 2.days.ago) }
    let_it_be(:registry_container_registry_5) { create(:container_repository_registry, state: :failed, container_repository_id: container_repository_5.id, last_synced_at: 6.days.ago) }
    let_it_be(:registry_container_registry_6) { create(:container_repository_registry, state: :failed, container_repository_id: container_repository_6.id, last_synced_at: nil) }

    it 'returns registries for projects that have been recently updated' do
      registries = subject.find_retryable_dirty_registries(batch_size: 10)

      expect(registries).to match_ids(registry_container_registry_3, registry_container_registry_4, registry_container_registry_5, registry_container_registry_6)
    end

    it 'excludes except_ids' do
      registries = subject.find_retryable_dirty_registries(batch_size: 10, except_ids: [container_repository_4.id, container_repository_5.id, container_repository_6.id])

      expect(registries).to match_ids(registry_container_registry_3)
    end
  end
end
