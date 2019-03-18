# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::Fdw::GeoNodeNamespaceLink, :geo, type: :model do
  context 'relationships' do
    it { is_expected.to belong_to(:geo_node).class_name('Geo::Fdw::GeoNode').inverse_of(:namespaces) }
    it { is_expected.to belong_to(:namespace).class_name('Geo::Fdw::Namespace').inverse_of(:geo_nodes) }
  end
end
