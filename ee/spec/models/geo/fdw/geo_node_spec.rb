# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::Fdw::GeoNode, :geo, type: :model do
  context 'relationships' do
    it { is_expected.to have_many(:geo_node_namespace_links).class_name('Geo::Fdw::GeoNodeNamespaceLink') }
    it { is_expected.to have_many(:namespaces).class_name('Geo::Fdw::Namespace').through(:geo_node_namespace_links) }
  end

  describe '#projects', :geo_fdw do
    let(:node) { create(:geo_node) }
    let(:group_1) { create(:group) }
    let(:group_2) { create(:group) }
    let(:nested_group_1) { create(:group, parent: group_1) }
    let(:project_1) { create(:project, group: group_1) }
    let(:project_2) { create(:project, group: nested_group_1) }
    let(:project_3) { create(:project, :broken_storage, group: group_2) }

    subject { described_class.find(node.id) }

    it 'returns all registries without selective sync' do
      expect(subject.projects).to match_ids(project_1, project_2, project_3)
    end

    it 'returns projects that belong to the namespaces with selective sync by namespace' do
      node.update!(selective_sync_type: 'namespaces', namespaces: [group_1])

      expect(subject.projects).to match_ids(project_1, project_2)
    end

    it 'returns projects that belong to the shards with selective sync by shard' do
      node.update!(selective_sync_type: 'shards', selective_sync_shards: %w[broken])

      expect(subject.projects).to match_ids(project_3)
    end

    it 'returns nothing if an unrecognised selective sync type is used' do
      node.update_attribute(:selective_sync_type, 'unknown')

      expect(subject.projects).to be_empty
    end
  end

  # Disable transactions via :delete method because a foreign table
  # can't see changes inside a transaction of a different connection.
  describe '#project_registries', :geo_fdw do
    let(:node) { create(:geo_node) }
    let(:group_1) { create(:group) }
    let(:group_2) { create(:group) }
    let(:nested_group_1) { create(:group, parent: group_1) }
    let(:project_1) { create(:project, group: group_1) }
    let(:project_2) { create(:project, group: nested_group_1) }
    let(:project_3) { create(:project, :broken_storage, group: group_2) }
    let!(:registry_1) { create(:geo_project_registry, project: project_1) }
    let!(:registry_2) { create(:geo_project_registry, project: project_2) }
    let!(:registry_3) { create(:geo_project_registry, project: project_3) }

    subject { described_class.find(node.id) }

    it 'returns all registries without selective sync' do
      expect(subject.project_registries).to match_array([registry_1, registry_2, registry_3])
    end

    it 'returns registries where projects belong to the namespaces with selective sync by namespace' do
      node.update!(selective_sync_type: 'namespaces', namespaces: [group_1])

      expect(subject.project_registries).to match_array([registry_1, registry_2])
    end

    it 'returns registries where projects belong to the shards with selective sync by shard' do
      node.update!(selective_sync_type: 'shards', selective_sync_shards: %w[broken])

      expect(subject.project_registries).to match_array([registry_3])
    end

    it 'returns nothing if an unrecognised selective sync type is used' do
      node.update_attribute(:selective_sync_type, 'unknown')

      expect(subject.project_registries).to be_empty
    end
  end
end
