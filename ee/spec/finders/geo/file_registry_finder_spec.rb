# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::FileRegistryFinder, :geo, :geo_fdw do
  include ::EE::GeoHelpers

  context 'with abstract methods' do
    %w[
      syncable
      count_syncable
      count_synced
      count_failed
      count_synced_missing_on_primary
      count_registry
      find_unsynced
      find_migrated_local
      find_retryable_failed_registries
      find_retryable_synced_missing_on_primary_registries
    ].each do |required_method|
      it "requires subclasses to implement #{required_method}" do
        expect { subject.send(required_method) }.to raise_error(NotImplementedError)
      end
    end
  end

  describe '#local_storage_only?' do
    subject { described_class.new(current_node_id: geo_node.id) }

    context 'sync_object_storage is enabled' do
      let(:geo_node) { create(:geo_node, sync_object_storage: true) }

      it 'returns false' do
        expect(subject.local_storage_only?).to be_falsey
      end
    end

    context 'sync_object_storage is disabled' do
      let(:geo_node) { create(:geo_node, sync_object_storage: false) }

      it 'returns true' do
        expect(subject.local_storage_only?).to be_truthy
      end
    end
  end
end
