# frozen_string_literal: true

require 'spec_helper'

describe Geo::BlobUploadService do
  include ::EE::GeoHelpers

  let_it_be(:primary) { create(:geo_node, :primary) }
  let_it_be(:secondary) { create(:geo_node) }

  subject { described_class.new() }
end
