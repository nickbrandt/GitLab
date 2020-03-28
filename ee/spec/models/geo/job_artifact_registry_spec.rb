# frozen_string_literal: true

require 'spec_helper'

describe Geo::JobArtifactRegistry, :geo do
  it_behaves_like 'a BulkInsertSafe model', Geo::JobArtifactRegistry do
    let(:valid_items_for_bulk_insertion) { build_list(:geo_job_artifact_registry, 10) }
    let(:invalid_items_for_bulk_insertion) { [] } # class does not have any validations defined
  end
end
