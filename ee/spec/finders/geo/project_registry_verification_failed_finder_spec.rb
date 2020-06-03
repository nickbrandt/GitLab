# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::ProjectRegistryVerificationFailedFinder, :geo, :geo_fdw do
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
    let!(:registry_verification_failed) { create(:geo_project_registry, :repository_verification_failed, :wiki_verification_failed, project: project_1) }
    let!(:registry_repository_verification_failed) { create(:geo_project_registry, :repository_verification_failed, :wiki_verified, project: project_2) }
    let!(:registry_wiki_verification_failed) { create(:geo_project_registry, :repository_verified, :wiki_verification_failed, project: project_3) }
    let!(:registry_wiki_verification_failed_broken_shard) { create(:geo_project_registry, :repository_verified, :wiki_verification_failed, project: project_4) }
    let!(:registry_repository_verification_failed_broken_shard) { create(:geo_project_registry, :repository_verification_failed, :wiki_verified, project: project_5) }
    let!(:registry_verified) { create(:geo_project_registry, :repository_verified, :wiki_verified) }

    context 'with repository type' do
      subject { described_class.new(current_node: node, type: :repository) }

      context 'without selective sync' do
        it 'returns all failed registries' do
          expect(subject.execute).to contain_exactly(registry_verification_failed, registry_repository_verification_failed, registry_repository_verification_failed_broken_shard)
        end
      end

      context 'with selective sync by namespace' do
        it 'returns failed registries where projects belongs to the namespaces' do
          node.update!(selective_sync_type: 'namespaces', namespaces: [group_1])

          expect(subject.execute).to contain_exactly(registry_verification_failed, registry_repository_verification_failed)
        end
      end

      context 'with selective sync by shard' do
        it 'returns failed registries where projects belongs to the shards' do
          node.update!(selective_sync_type: 'shards', selective_sync_shards: ['broken'])

          expect(subject.execute).to contain_exactly(registry_repository_verification_failed_broken_shard)
        end
      end
    end

    context 'with wiki type' do
      subject { described_class.new(current_node: node, type: :wiki) }

      context 'without selective sync' do
        it 'returns all failed registries' do
          expect(subject.execute).to contain_exactly(registry_verification_failed, registry_wiki_verification_failed, registry_wiki_verification_failed_broken_shard)
        end
      end

      context 'with selective sync by namespace' do
        it 'returns failed registries where projects belongs to the namespaces' do
          node.update!(selective_sync_type: 'namespaces', namespaces: [group_1])

          expect(subject.execute).to contain_exactly(registry_verification_failed, registry_wiki_verification_failed)
        end
      end

      context 'with selective sync by shard' do
        it 'returns failed registries where projects belongs to the shards' do
          node.update!(selective_sync_type: 'shards', selective_sync_shards: ['broken'])

          expect(subject.execute).to contain_exactly(registry_wiki_verification_failed_broken_shard)
        end
      end
    end

    context 'with no type' do
      subject { described_class.new(current_node: node, type: :invalid) }

      context 'without selective sync' do
        it 'returns all failed registries' do
          expect(subject.execute).to contain_exactly(registry_verification_failed, registry_repository_verification_failed, registry_wiki_verification_failed, registry_repository_verification_failed_broken_shard, registry_wiki_verification_failed_broken_shard)
        end
      end

      context 'with selective sync by namespace' do
        it 'returns all failed registries where projects belongs to the namespaces' do
          node.update!(selective_sync_type: 'namespaces', namespaces: [group_1])

          expect(subject.execute).to contain_exactly(registry_verification_failed, registry_repository_verification_failed, registry_wiki_verification_failed)
        end
      end

      context 'with selective sync by shard' do
        it 'returns all failed registries where projects belongs to the shards' do
          node.update!(selective_sync_type: 'shards', selective_sync_shards: ['broken'])

          expect(subject.execute).to contain_exactly(registry_repository_verification_failed_broken_shard, registry_wiki_verification_failed_broken_shard)
        end
      end
    end
  end
end
