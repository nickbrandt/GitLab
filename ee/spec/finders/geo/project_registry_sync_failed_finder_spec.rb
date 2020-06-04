# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::ProjectRegistrySyncFailedFinder, :geo, :geo_fdw do
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
    let!(:registry_failed) { create(:geo_project_registry, :sync_failed, project: project_1) }
    let!(:registry_repository_failed) { create(:geo_project_registry, :synced, :repository_sync_failed, project: project_2) }
    let!(:registry_wiki_failed) { create(:geo_project_registry, :synced, :wiki_sync_failed, project: project_3) }
    let!(:registry_wiki_failed_broken_shard) { create(:geo_project_registry, :synced, :wiki_sync_failed, project: project_4) }
    let!(:registry_repository_failed_broken_shard) { create(:geo_project_registry, :synced, :repository_sync_failed, project: project_5) }
    let!(:registry_synced) { create(:geo_project_registry, :synced) }

    context 'with repository type' do
      subject { described_class.new(current_node: node, type: :repository) }

      context 'without selective sync' do
        it 'returns all failed registries' do
          expect(subject.execute).to match_array([registry_failed, registry_repository_failed, registry_repository_failed_broken_shard])
        end
      end

      context 'with selective sync by namespace' do
        it 'returns failed registries where projects belongs to the namespaces' do
          node.update!(selective_sync_type: 'namespaces', namespaces: [group_1])

          expect(subject.execute).to match_array([registry_failed, registry_repository_failed])
        end
      end

      context 'with selective sync by shard' do
        it 'returns failed registries where projects belongs to the shards' do
          node.update!(selective_sync_type: 'shards', selective_sync_shards: ['broken'])

          expect(subject.execute).to match_array([registry_repository_failed_broken_shard])
        end
      end
    end

    context 'with wiki type' do
      subject { described_class.new(current_node: node, type: :wiki) }

      context 'without selective sync' do
        it 'returns all failed registries' do
          expect(subject.execute).to match_array([registry_failed, registry_wiki_failed, registry_wiki_failed_broken_shard])
        end
      end

      context 'with selective sync by namespace' do
        it 'returns failed registries where projects belongs to the namespaces' do
          node.update!(selective_sync_type: 'namespaces', namespaces: [group_1])

          expect(subject.execute).to match_array([registry_failed, registry_wiki_failed])
        end
      end

      context 'with selective sync by shard' do
        it 'returns failed registries where projects belongs to the shards' do
          node.update!(selective_sync_type: 'shards', selective_sync_shards: ['broken'])

          expect(subject.execute).to match_array([registry_wiki_failed_broken_shard])
        end
      end
    end

    context 'with no type' do
      subject { described_class.new(current_node: node, type: :invalid) }

      context 'without selective sync' do
        it 'returns all failed registries' do
          expect(subject.execute).to match_array([registry_failed, registry_repository_failed, registry_wiki_failed, registry_repository_failed_broken_shard, registry_wiki_failed_broken_shard])
        end
      end

      context 'with selective sync by namespace' do
        it 'returns all failed registries where projects belongs to the namespaces' do
          node.update!(selective_sync_type: 'namespaces', namespaces: [group_1])

          expect(subject.execute).to match_array([registry_failed, registry_repository_failed, registry_wiki_failed])
        end
      end

      context 'with selective sync by shard' do
        it 'returns all failed registries where projects belongs to the shards' do
          node.update!(selective_sync_type: 'shards', selective_sync_shards: ['broken'])

          expect(subject.execute).to match_array([registry_repository_failed_broken_shard, registry_wiki_failed_broken_shard])
        end
      end
    end
  end
end
