# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::Fdw::GeoNodeNamespaceLink, :geo, type: :model do
  context 'relationships' do
    it { is_expected.to belong_to(:geo_node).class_name('Geo::Fdw::GeoNode').inverse_of(:namespaces) }
  end
end
