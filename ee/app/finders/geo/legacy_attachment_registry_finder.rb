# frozen_string_literal: true

module Geo
  class LegacyAttachmentRegistryFinder < RegistryFinder
    def syncable
      attachments.geo_syncable
    end

    def attachments
      if selective_sync?
        Upload.where(group_uploads.or(project_uploads).or(other_uploads))
      else
        Upload.all
      end
    end

    private

    # rubocop: disable CodeReuse/ActiveRecord
    def group_uploads
      namespace_ids =
        if current_node.selective_sync_by_namespaces?
          Gitlab::ObjectHierarchy.new(current_node.namespaces).base_and_descendants.select(:id)
        elsif current_node.selective_sync_by_shards?
          leaf_groups = Namespace.where(id: current_node.projects.select(:namespace_id))
          Gitlab::ObjectHierarchy.new(leaf_groups).base_and_ancestors.select(:id)
        else
          Namespace.none
        end

      # This query was intentionally converted to a raw one to get it work in Rails 5.0.
      # In Rails 5.0 and 5.1 there's a bug: https://github.com/rails/arel/issues/531
      # Please convert it back when on rails 5.2 as it works again as expected since 5.2.
      namespace_ids_in_sql = Arel::Nodes::SqlLiteral.new("#{upload_table.name}.#{upload_table[:model_id].name} IN (#{namespace_ids.to_sql})")

      upload_table[:model_type].eq('Namespace').and(namespace_ids_in_sql)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def project_uploads
      project_ids = current_node.projects.select(:id)

      # This query was intentionally converted to a raw one to get it work in Rails 5.0.
      # In Rails 5.0 and 5.1 there's a bug: https://github.com/rails/arel/issues/531
      # Please convert it back when on rails 5.2 as it works again as expected since 5.2.
      project_ids_in_sql = Arel::Nodes::SqlLiteral.new("#{upload_table.name}.#{upload_table[:model_id].name} IN (#{project_ids.to_sql})")

      upload_table[:model_type].eq('Project').and(project_ids_in_sql)
    end

    def other_uploads
      upload_table[:model_type].not_in(%w[Namespace Project])
    end

    def upload_table
      Upload.arel_table
    end
  end
end
