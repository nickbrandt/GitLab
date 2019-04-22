# frozen_string_literal: true

module Geo::SelectiveSync
  extend ActiveSupport::Concern

  def selective_sync?
    selective_sync_type.present?
  end

  def selective_sync_by_namespaces?
    selective_sync_type == 'namespaces'
  end

  def selective_sync_by_shards?
    selective_sync_type == 'shards'
  end

  private

  def selected_namespaces_and_descendants
    relation = selected_namespaces_and_descendants_cte.apply_to(namespaces_model.all)
    relation.extend(Gitlab::Database::ReadOnlyRelation)
    relation
  end

  def selected_namespaces_and_descendants_cte
    cte = Gitlab::SQL::RecursiveCTE.new(:base_and_descendants)

    cte << geo_node_namespace_links
      .select(geo_node_namespace_links_table[:namespace_id].as('id'))
      .except(:order)

    # Recursively get all the descendants of the base set.
    cte << namespaces_model
      .select(namespaces_table[:id])
      .from([namespaces_table, cte.table])
      .where(namespaces_table[:parent_id].eq(cte.table[:id]))
      .except(:order)

    cte
  end

  # This concern doesn't define a namespaces relation. That's done in ::GeoNode
  # or ::Geo::Fdw::GeoNode respectively. So when we use the same code from the
  # two places, they act differently - the first doesn't use FDW, the second does.
  def namespaces_model
    namespaces.model
  end

  # This concern doesn't define a namespaces relation. That's done in ::GeoNode
  # or ::Geo::Fdw::GeoNode respectively. So when we use the same code from the
  # two places, they act differently - the first doesn't use FDW, the second does.
  def namespaces_table
    namespaces.arel_table
  end

  # This concern doesn't define a geo_node_namespace_links relation. That's
  # done in ::GeoNode or ::Geo::Fdw::GeoNode respectively. So when we use the
  # same code from the two places, they act differently - the first doesn't
  # use FDW, the second does.
  def geo_node_namespace_links_table
    geo_node_namespace_links.arel_table
  end
end
