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

      def project_model
        Geo::Fdw::Project
      end
    end
  end
end
