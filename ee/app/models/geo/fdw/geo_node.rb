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

      def projects_outside_selective_sync
        projects = if selective_sync_by_namespaces?
                     projects_outside_selected_namespaces
                   elsif selective_sync_by_shards?
                     projects_outside_selected_shards
                   else
                     Geo::Fdw::Project.none
                   end

        projects.inner_join_project_registry
      end

      def job_artifacts
        Geo::Fdw::Ci::JobArtifact.all unless selective_sync?

        query = Geo::Fdw::Ci::JobArtifact.project_id_in(projects).select(:id)
        cte = Gitlab::SQL::CTE.new(:restricted_job_artifacts, query)
        fdw_job_artifact_table = Geo::Fdw::Ci::JobArtifact.arel_table

        inner_join_restricted_job_artifacts =
          cte.table
            .join(fdw_job_artifact_table, Arel::Nodes::InnerJoin)
            .on(cte.table[:id].eq(fdw_job_artifact_table[:id]))
            .join_sources

        Geo::Fdw::Ci::JobArtifact
          .with(cte.to_arel)
          .from(cte.table)
          .joins(inner_join_restricted_job_artifacts)
      end

      def lfs_objects
        return Geo::Fdw::LfsObject.all unless selective_sync?

        query = Geo::Fdw::LfsObjectsProject.project_id_in(projects).select(:lfs_object_id)
        cte = Gitlab::SQL::CTE.new(:restricted_lfs_objects, query)
        fdw_lfs_object_table = Geo::Fdw::LfsObject.arel_table

        inner_join_restricted_lfs_objects =
          cte.table
            .join(fdw_lfs_object_table, Arel::Nodes::InnerJoin)
            .on(cte.table[:lfs_object_id].eq(fdw_lfs_object_table[:id]))
            .join_sources

        Geo::Fdw::LfsObject
          .with(cte.to_arel)
          .from(cte.table)
          .joins(inner_join_restricted_lfs_objects)
      end

      def lfs_object_registries
        return Geo::LfsObjectRegistry.all unless selective_sync?

        Gitlab::Geo::Fdw::LfsObjectRegistryQueryBuilder.new
          .for_lfs_objects(lfs_objects)
      end

      def projects
        return Geo::Fdw::Project.all unless selective_sync?

        if selective_sync_by_namespaces?
          projects_for_selected_namespaces
        elsif selective_sync_by_shards?
          projects_for_selected_shards
        else
          Geo::Fdw::Project.none
        end
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

      def container_repositories
        return Geo::Fdw::ContainerRepository.all unless selective_sync?

        Geo::Fdw::ContainerRepository.project_id_in(projects)
      end

      private

      def projects_for_selected_namespaces
        Geo::Fdw::Project
          .within_namespaces(selected_namespaces_and_descendants.select(:id))
      end

      def projects_for_selected_shards
        Geo::Fdw::Project.within_shards(selective_sync_shards)
      end

      def registries_for_selected_namespaces
        Gitlab::Geo::Fdw::ProjectRegistryQueryBuilder.new
          .within_namespaces(selected_namespaces_and_descendants.select(:id))
      end

      def registries_for_selected_shards
        Gitlab::Geo::Fdw::ProjectRegistryQueryBuilder.new
          .within_shards(selective_sync_shards)
      end

      def project_model
        Geo::Fdw::Project
      end

      def uploads_model
        Geo::Fdw::Upload
      end
    end
  end
end
