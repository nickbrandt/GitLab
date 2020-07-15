# frozen_string_literal: true

module Geo::SelectiveSync
  extend ActiveSupport::Concern

  # @return [ActiveRecord::Relation<Upload>] scope of everything that should be synced
  def attachments
    attachments_selective_sync_scope.merge(attachments_object_storage_scope)
  end

  def projects_outside_selected_namespaces
    return project_model.none unless selective_sync_by_namespaces?

    cte_query = selected_namespaces_and_descendants_cte
    cte_table = cte_query.table

    join_statement =
      projects_table
        .join(cte_table, Arel::Nodes::OuterJoin)
        .on(projects_table[:namespace_id].eq(cte_table[:id]))

    project_model
      .joins(join_statement.join_sources)
      .where(cte_table[:id].eq(nil))
      .with
      .recursive(cte_query.to_arel)
  end

  def projects_outside_selected_shards
    return project_model.none unless selective_sync_by_shards?

    project_model.outside_shards(selective_sync_shards)
  end

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

  # @return [ActiveRecord::Relation<Upload>] scope observing object storage settings
  def attachments_object_storage_scope
    return uploads_model.all if sync_object_storage?

    uploads_model.with_files_stored_locally
  end

  # @return [ActiveRecord::Relation<Upload>] scope observing selective sync settings
  def attachments_selective_sync_scope
    if selective_sync?
      uploads_model.where(group_attachments.or(project_attachments).or(other_attachments))
    else
      uploads_model.all
    end
  end

  def selected_namespaces_and_descendants
    relation = selected_namespaces_and_descendants_cte.apply_to(namespaces_model.all)
    read_only(relation)
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

  def selected_leaf_namespaces_and_ancestors
    relation = selected_leaf_namespaces_and_ancestors_cte.apply_to(namespaces_model.all)
    read_only(relation)
  end

  # Returns a CTE selecting namespace IDs for selected shards
  #
  # When we need to sync resources that are only associated with namespaces,
  # but the instance is selectively syncing by shard, we must sync every
  # namespace of every project in those shards. We must also sync every
  # ancestor of those namespaces.
  def selected_leaf_namespaces_and_ancestors_cte
    cte = Gitlab::SQL::RecursiveCTE.new(:base_and_ancestors)

    cte << namespaces_model
      .select(namespaces_table[:id], namespaces_table[:parent_id])
      .where(id: projects.select(:namespace_id))

    # Recursively get all the ancestors of the base set.
    cte << namespaces_model
      .select(namespaces_table[:id], namespaces_table[:parent_id])
      .from([namespaces_table, cte.table])
      .where(namespaces_table[:id].eq(cte.table[:parent_id]))
      .except(:order)

    cte
  end

  def read_only(relation)
    # relations using a CTE are not safe to use with update_all as it will
    # throw away the CTE, hence we mark them as read-only.
    relation.extend(Gitlab::Database::ReadOnlyRelation)
    relation
  end

  def group_attachments
    namespaces =
      if selective_sync_by_namespaces?
        selected_namespaces_and_descendants
      elsif selective_sync_by_shards?
        selected_leaf_namespaces_and_ancestors
      else
        namespaces_model.none
      end

    attachments_for_model_type_with_id_in('Namespace', namespaces.select(:id))
  end

  def project_attachments
    attachments_for_model_type_with_id_in('Project', projects.select(:id))
  end

  def other_attachments
    uploads_table[:model_type].not_in(%w[Namespace Project])
  end

  def attachments_for_model_type_with_id_in(model_type, model_ids)
    uploads_table[:model_type]
        .eq(model_type)
        .and(
          uploads_table[:model_id].in(model_ids.arel)
        )
  end

  # This concern doesn't define a geo_node_namespace_links relation. That's
  # done in ::GeoNode or ::Geo::Fdw::GeoNode respectively. So when we use the
  # same code from the two places, they act differently - the first doesn't
  # use FDW, the second does.
  def geo_node_namespace_links_table
    geo_node_namespace_links.arel_table
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

  def project_model
    raise NotImplementedError,
      "#{self.class} does not implement #{__method__}"
  end

  def projects_table
    project_model.arel_table
  end

  def uploads_model
    raise NotImplementedError,
      "#{self.class} does not implement #{__method__}"
  end

  def uploads_table
    uploads_model.arel_table
  end
end
