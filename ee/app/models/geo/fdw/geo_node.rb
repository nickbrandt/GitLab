# frozen_string_literal: true

module Geo
  module Fdw
    class GeoNode < ::Geo::BaseFdw
      include ::Geo::SelectiveSync

      self.primary_key = :id
      self.inheritance_column = nil
      self.table_name = Gitlab::Geo::Fdw.foreign_table_name('geo_nodes')

      serialize :selective_sync_shards, Array # rubocop:disable Cop/ActiveRecordSerialize

      has_many :geo_node_namespace_links, class_name: 'Geo::Fdw::GeoNodeNamespaceLink'
      has_many :namespaces, class_name: 'Geo::Fdw::Namespace', through: :geo_node_namespace_links

      def self.fdw_inner_join_projects
        project_registries_table = Geo::ProjectRegistry.arel_table
        fdw_projects_table = Geo::Fdw::Project.arel_table

        project_registries_table
          .join(fdw_projects_table, Arel::Nodes::InnerJoin)
          .on(project_registries_table[:project_id].eq(fdw_projects_table[:id]))
          .join_sources
      end

      def self.fdw_inner_join_repository_state
        project_registries_table = Geo::ProjectRegistry.arel_table
        fdw_repository_state_table = Geo::Fdw::ProjectRepositoryState.arel_table

        project_registries_table
          .join(fdw_repository_state_table, Arel::Nodes::InnerJoin)
          .on(project_registries_table[:project_id].eq(fdw_repository_state_table[:project_id]))
          .join_sources
      end

      def self.fdw_registries_pending_verification
        fdw_repositories_pending_verification.or(fdw_wikis_pending_verification)
      end

      def self.fdw_repositories_pending_verification
        fdw_repository_state_table = Geo::Fdw::ProjectRepositoryState.arel_table

        Geo::ProjectRegistry.repositories_pending_verification
          .and(fdw_repository_state_table[:repository_verification_checksum].not_eq(nil))
      end

      def self.fdw_wikis_pending_verification
        fdw_repository_state_table = Geo::Fdw::ProjectRepositoryState.arel_table

        Geo::ProjectRegistry.wikis_pending_verification
          .and(fdw_repository_state_table[:wiki_verification_checksum].not_eq(nil))
      end

      def project_registries
        return Geo::ProjectRegistry.all unless selective_sync?

        if selective_sync_by_namespaces?
          registries_for_selected_namespaces
        elsif selective_sync_by_shards?
          registries_for_selected_shards
        else
          Geo::ProjectRegistry.none
        end
      end

      private

      def registries_for_selected_namespaces
        query = selected_namespaces_and_descendants

        Geo::ProjectRegistry
          .joins(self.class.fdw_inner_join_projects)
          .where(fdw_projects_table.name => { namespace_id: query.select(:id) })
      end

      def selected_namespaces_and_descendants
        relation = selected_namespaces_and_descendants_cte.apply_to(Geo::Fdw::Namespace.all)
        relation.extend(Gitlab::Database::ReadOnlyRelation)
        relation
      end

      def selected_namespaces_and_descendants_cte
        cte = Gitlab::SQL::RecursiveCTE.new(:base_and_descendants)

        cte << geo_node_namespace_links
          .select(fdw_geo_node_namespace_links_table[:namespace_id].as('id'))
          .except(:order)

        # Recursively get all the descendants of the base set.
        cte << Geo::Fdw::Namespace
          .select(fdw_namespaces_table[:id])
          .from([fdw_namespaces_table, cte.table])
          .where(fdw_namespaces_table[:parent_id].eq(cte.table[:id]))
          .except(:order)

        cte
      end

      def registries_for_selected_shards
        Geo::ProjectRegistry
          .joins(self.class.fdw_inner_join_projects)
          .where(fdw_projects_table.name => { repository_storage: selective_sync_shards })
      end

      def fdw_projects_table
        Geo::Fdw::Project.arel_table
      end

      def fdw_namespaces_table
        Geo::Fdw::Namespace.arel_table
      end

      def fdw_geo_node_namespace_links_table
        Geo::Fdw::GeoNodeNamespaceLink.arel_table
      end
    end
  end
end
