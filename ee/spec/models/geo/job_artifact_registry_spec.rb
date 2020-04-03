# frozen_string_literal: true

require 'spec_helper'

describe Geo::JobArtifactRegistry, :geo do
  include EE::GeoHelpers

  it_behaves_like 'a BulkInsertSafe model', Geo::JobArtifactRegistry do
    let(:valid_items_for_bulk_insertion) { build_list(:geo_job_artifact_registry, 10) }
    let(:invalid_items_for_bulk_insertion) { [] } # class does not have any validations defined
  end

  describe '.replication_enabled?' do
    context 'when Object Storage is enabled' do
      before do
        allow(JobArtifactUploader).to receive(:object_store_enabled?).and_return(true)
      end

      it 'returns true when Geo Object Storage replication is enabled' do
        stub_current_geo_node(double(sync_object_storage?: true))

        expect(Geo::JobArtifactRegistry.replication_enabled?).to be_truthy
      end

      it 'returns false when Geo Object Storage replication is disabled' do
        stub_current_geo_node(double(sync_object_storage?: false))

        expect(Geo::JobArtifactRegistry.replication_enabled?).to be_falsey
      end
    end

    it 'returns true when Object Storage is disabled' do
      allow(JobArtifactUploader).to receive(:object_store_enabled?).and_return(false)

      expect(Geo::JobArtifactRegistry.replication_enabled?).to be_truthy
    end
  end
end
