# frozen_string_literal: true

module Geo
  module Fdw
    class GeoNode < ::Geo::BaseFdw
      self.primary_key = :id
      self.inheritance_column = nil
      self.table_name = Gitlab::Geo::Fdw.foreign_table_name('geo_nodes')

      serialize :selective_sync_shards, Array # rubocop:disable Cop/ActiveRecordSerialize

      has_many :geo_node_namespace_links, class_name: 'Geo::Fdw::GeoNodeNamespaceLink'
    end
  end
end
