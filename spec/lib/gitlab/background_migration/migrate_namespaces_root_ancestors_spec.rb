# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::MigrateNamespacesRootAncestors, schema: 20200702151210 do
  let(:namespaces) { table(:namespaces) }

  describe '#perform' do
    it 'migrates namespaces.root_ancestor_id' do
      root_ns = namespaces.create!(name: 'root_ns', path: 'root_ns', root_ancestor_id: nil)
      ns1 = namespaces.create!(name: 'ns1', path: 'ns1', root_ancestor_id: nil, parent_id: root_ns.id)

      another_root_ns = namespaces.create!(name: 'another_root_ns', path: 'another_root_ns', root_ancestor_id: nil)

      expect { subject.perform(namespaces.minimum(:id), namespaces.maximum(:id)) }.to change { namespaces.where('root_ancestor_id IS NOT NULL').count }.from(0).to(3)
      expect(root_ns.reload.root_ancestor_id).to eq(root_ns.id)
      expect(ns1.reload.root_ancestor_id).to eq(root_ns.id)
      expect(another_root_ns.reload.root_ancestor_id).to eq(another_root_ns.id)
    end
  end
end
