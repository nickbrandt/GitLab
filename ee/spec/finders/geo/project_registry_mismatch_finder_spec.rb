# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::ProjectRegistryMismatchFinder, :geo, :geo_fdw do
  describe '#execute' do
    let(:node) { create(:geo_node) }
    let(:group_1) { create(:group) }
    let(:group_2) { create(:group) }
    let(:nested_group_1) { create(:group, parent: group_1) }
    let(:project_1) { create(:project, group: group_1) }
    let(:project_2) { create(:project, group: nested_group_1) }
    let(:project_3) { create(:project, group: nested_group_1) }
    let(:project_4) { create(:project, :broken_storage, group: group_2) }
    let(:project_5) { create(:project, :broken_storage, group: group_2) }
    let!(:registry_mismatch) { create(:geo_project_registry, :repository_checksum_mismatch, :wiki_checksum_mismatch, project: project_1) }
    let!(:registry_repository_mismatch) { create(:geo_project_registry, :repository_checksum_mismatch, :wiki_verified, project: project_2) }
    let!(:registry_wiki_mismatch) { create(:geo_project_registry, :repository_verified, :wiki_checksum_mismatch, project: project_3) }
    let!(:registry_wiki_mismatch_broken_shard) { create(:geo_project_registry, :repository_verified, :wiki_checksum_mismatch, project: project_4) }
    let!(:registry_repository_mismatch_broken_shard) { create(:geo_project_registry, :repository_checksum_mismatch, :wiki_verified, project: project_5) }
    let!(:registry_verified) { create(:geo_project_registry, :repository_verified, :wiki_verified) }

    context 'with repository type' do
      subject { described_class.new(current_node: node, type: :repository) }

      context 'without selective sync' do
        it 'returns all mismatch registries' do
          expect(subject.execute).to contain_exactly(registry_mismatch, registry_repository_mismatch, registry_repository_mismatch_broken_shard)
        end
      end

      context 'with selective sync by namespace' do
        it 'returns mismatch registries where projects belongs to the namespaces' do
          node.update!(selective_sync_type: 'namespaces', namespaces: [group_1])

          expect(subject.execute).to contain_exactly(registry_mismatch, registry_repository_mismatch)
        end
      end

      context 'with selective sync by shard' do
        it 'returns mismatch registries where projects belongs to the shards' do
          node.update!(selective_sync_type: 'shards', selective_sync_shards: ['broken'])

          expect(subject.execute).to contain_exactly(registry_repository_mismatch_broken_shard)
        end
      end
    end

    context 'with wiki type' do
      subject { described_class.new(current_node: node, type: :wiki) }

      context 'without selective sync' do
        it 'returns all mismatch registries' do
          expect(subject.execute).to contain_exactly(registry_mismatch, registry_wiki_mismatch, registry_wiki_mismatch_broken_shard)
        end
      end

      context 'with selective sync by namespace' do
        it 'returns mismatch registries where projects belongs to the namespaces' do
          node.update!(selective_sync_type: 'namespaces', namespaces: [group_1])

          expect(subject.execute).to contain_exactly(registry_mismatch, registry_wiki_mismatch)
        end
      end

      context 'with selective sync by shard' do
        it 'returns mismatch registries where projects belongs to the shards' do
          node.update!(selective_sync_type: 'shards', selective_sync_shards: ['broken'])

          expect(subject.execute).to contain_exactly(registry_wiki_mismatch_broken_shard)
        end
      end
    end

    context 'with invalid type' do
      subject { described_class.new(current_node: node, type: :invalid) }

      context 'without selective sync' do
        it 'returns all mismatch registries' do
          expect(subject.execute).to contain_exactly(registry_mismatch, registry_repository_mismatch, registry_wiki_mismatch, registry_repository_mismatch_broken_shard, registry_wiki_mismatch_broken_shard)
        end
      end

      context 'with selective sync by namespace' do
        it 'returns all mismatch registries where projects belongs to the namespaces' do
          node.update!(selective_sync_type: 'namespaces', namespaces: [group_1])

          expect(subject.execute).to contain_exactly(registry_mismatch, registry_repository_mismatch, registry_wiki_mismatch)
        end
      end

      context 'with selective sync by shard' do
        it 'returns all mismatch registries where projects belongs to the shards' do
          node.update!(selective_sync_type: 'shards', selective_sync_shards: ['broken'])

          expect(subject.execute).to contain_exactly(registry_repository_mismatch_broken_shard, registry_wiki_mismatch_broken_shard)
        end
      end
    end
  end
end
