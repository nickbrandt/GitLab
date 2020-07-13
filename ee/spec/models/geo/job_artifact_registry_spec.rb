# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::JobArtifactRegistry, :geo do
  include EE::GeoHelpers

  it_behaves_like 'a BulkInsertSafe model', Geo::JobArtifactRegistry do
    let(:valid_items_for_bulk_insertion) { build_list(:geo_job_artifact_registry, 10) }
    let(:invalid_items_for_bulk_insertion) { [] } # class does not have any validations defined
  end

  describe '.insert_for_model_ids' do
    it 'returns an array with the primary key values for all inserted records' do
      ids = described_class.insert_for_model_ids([1])

      expect(ids).to contain_exactly(a_kind_of(Integer))
    end

    it 'defaults success column to false for all inserted records' do
      ids = described_class.insert_for_model_ids([1])

      expect(described_class.where(id: ids).pluck(:success)).to eq([false])
    end
  end
end
