# frozen_string_literal: true

module Geo
  module Fdw
    class Namespace < ::Geo::BaseFdw
      include Routable

      self.primary_key = :id
      self.inheritance_column = nil
      self.table_name = Gitlab::Geo::Fdw.foreign_table_name('namespaces')

      has_many :geo_node_namespace_links, class_name: 'Geo::Fdw::GeoNodeNamespaceLink'
      has_many :geo_nodes, class_name: 'Geo::Fdw::GeoNode', through: :geo_node_namespace_links
      belongs_to :parent, class_name: "Namespace"
    end
  end
end
