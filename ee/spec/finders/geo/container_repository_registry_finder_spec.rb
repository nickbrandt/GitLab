# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Geo::ContainerRepositoryRegistryFinder, :geo, :geo_fdw do
  include ::EE::GeoHelpers

  let!(:secondary) { create(:geo_node) }
  let!(:container_repository) { create(:container_repository) }
  let!(:failed_registry) { create(:container_repository_registry, :sync_failed) }
  let!(:synced_registry) { create(:container_repository_registry, :synced) }

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
      it 'returns number of container repositories' do
        result = subject.count_syncable

        expect(result).to eq(3)
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

  context 'find all the things' do
    describe '#find_unsynced' do
      it 'returns repositories without an entry in the tracking database' do
        repositories = subject.find_unsynced(batch_size: 10)

        expect(repositories).to match_ids(container_repository)
      end

      it 'returns repositories without an entry in the tracking database, excluding exception list' do
        except_repository = create(:container_repository)
        repositories = subject.find_unsynced(batch_size: 10, except_repository_ids: [except_repository.id])

        expect(repositories).to match_ids(container_repository)
      end

      context 'with selective sync by namespace' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'namespaces', namespaces: [synced_group]) }

        it 'returns repositories without an entry in the tracking database, excluding exception list' do
          except_repository = create(:container_repository, project: synced_project)
          repository = create(:container_repository, project: synced_project, name: 'second')

          repositories = subject.find_unsynced(batch_size: 10, except_repository_ids: [except_repository.id])

          expect(repositories).to match_ids(repository)
        end
      end

      context 'with selective sync by shard' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'shards', selective_sync_shards: ['broken']) }

        it 'returns repositories without an entry in the tracking database' do
          unsynced_repository = create(:container_repository, project: unsynced_project)

          repositories = subject.find_unsynced(batch_size: 10)

          expect(repositories).to match_ids(unsynced_repository)
        end
      end
    end

    describe '#find_retryable_failed_ids' do
      it 'returns only registry that have to be retried' do
        result = subject.find_retryable_failed_ids(batch_size: 10)

        expect(result).to eq([failed_registry.container_repository_id])
      end

      it 'returns only registry that have to be retried, excluding exception list' do
        except_repository = create(:container_repository)
        create(:container_repository_registry, :sync_failed, container_repository: except_repository)

        result = subject.find_retryable_failed_ids(batch_size: 10, except_repository_ids: [except_repository.id])

        expect(result).to eq([failed_registry.container_repository_id])
      end
    end
  end
end
