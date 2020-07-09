# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::FileRegistryFinder, :geo do
  include ::EE::GeoHelpers

  context 'with abstract methods' do
    %w[
      replicables
      syncable
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
