# frozen_string_literal: true

module Geo
  module Fdw
    class GeoNodeNamespaceLink < ::Geo::BaseFdw
      self.table_name = Gitlab::Geo::Fdw.foreign_table_name('geo_node_namespace_links')

      belongs_to :geo_node, class_name: 'Geo::Fdw::GeoNode', inverse_of: :namespaces
      belongs_to :namespace, class_name: 'Geo::Fdw::Namespace', inverse_of: :geo_nodes
    end
  end
end
