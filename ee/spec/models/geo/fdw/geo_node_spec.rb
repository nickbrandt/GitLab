# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::Fdw::GeoNode, :geo, type: :model do
  context 'relationships' do
    it { is_expected.to have_many(:geo_node_namespace_links).class_name('Geo::Fdw::GeoNodeNamespaceLink') }
    it { is_expected.to have_many(:namespaces).class_name('Geo::Fdw::Namespace').through(:geo_node_namespace_links) }
  end
end
