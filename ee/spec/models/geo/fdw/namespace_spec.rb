# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::Fdw::Namespace, :geo, type: :model do
  context 'relationships' do
    it { is_expected.to have_many(:geo_node_namespace_links).class_name('Geo::Fdw::GeoNodeNamespaceLink') }
    it { is_expected.to have_many(:geo_nodes).class_name('Geo::Fdw::GeoNode').through(:geo_node_namespace_links) }
  end
end
