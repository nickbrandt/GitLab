# frozen_string_literal: true
#
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class CreateMissingPrometheusServicesForSharedClusterApplications
      include Gitlab::Database::MigrationHelpers

      module Migratable
        class Project < ActiveRecord::Base
          self.table_name = 'projects'

          def self.with_group_clusters
            joins("INNER JOIN namespaces ON namespaces.id = projects.namespace_id ")
              .joins("INNER JOIN cluster_groups ON cluster_groups.group_id = namespaces.id")
              .joins("INNER JOIN clusters ON clusters.id = cluster_groups.cluster_id AND clusters.cluster_type = 2")
              .joins("INNER JOIN clusters_applications_prometheus ON clusters_applications_prometheus.cluster_id = clusters.id
                      AND clusters_applications_prometheus.status IN (3,5)")
          end

          def self.with_missing_prometheus_services
            joins("LEFT JOIN services ON services.project_id = projects.id AND services.type = 'PrometheusService'")
              .where("services.id IS NULL")
          end
        end

        class Cluster < ActiveRecord::Base
          self.table_name = 'clusters'

          def self.has_prometheus_application?
            joins("INNER JOIN clusters_applications_prometheus ON clusters_applications_prometheus.cluster_id = clusters.id
                   AND clusters_applications_prometheus.status IN (3,5)")
              .where("clusters.cluster_type = 1").exists?
          end
        end

        class PrometheusService < ActiveRecord::Base
          self.table_name = 'services'

          def self.inactive_with_group_clusters
            joins("INNER JOIN projects ON projects.id = services.project_id")
              .joins("INNER JOIN namespaces ON namespaces.id = projects.namespace_id ")
              .joins("INNER JOIN cluster_groups ON cluster_groups.group_id = namespaces.id")
              .joins("INNER JOIN clusters ON clusters.id = cluster_groups.cluster_id AND clusters.cluster_type = 2")
              .joins("INNER JOIN clusters_applications_prometheus ON clusters_applications_prometheus.cluster_id = clusters.id
                      AND clusters_applications_prometheus.status IN (3,5)")
              .where("services.type = 'PrometheusService' AND services.active = FALSE AND services.properties = '{}'")
          end
        end
      end

      def perform(start_id, stop_id)
        migrate_group_clusters(start_id, stop_id)
        migrate_instance_clusters(start_id, stop_id)
      end

      private

      def migrate_instance_clusters(start_id, stop_id)
        return unless Migratable::Cluster.has_prometheus_application?

        ### Reactivate existing services which weren't configured manually
        Migratable::PrometheusService
            .joins("INNER JOIN projects ON projects.id = services.project_id")
            .where("services.type = 'PrometheusService' AND services.active = FALSE AND services.properties = '{}'")
            .where(projects: { id: start_id..stop_id })
            .update_all(active: true)

        ### create missing entries
        sql_values = Migratable::Project
                         .joins("LEFT JOIN services ON services.project_id = projects.id AND services.type = 'PrometheusService'")
                         .where(services: { id: nil }, projects: { id: start_id..stop_id })
                         .map(&method(:values_for_prometheus_service))

        insert_into_services(sql_values)
      end

      def migrate_group_clusters(start_id, stop_id)
        ### Reactivate existing services which weren't configured manually
        Migratable::PrometheusService
            .inactive_with_group_clusters
            .where(projects: { id: start_id..stop_id })
            .update_all(active: true)

        ### create missing entries
        sql_values = Migratable::Project
                         .with_group_clusters
                         .with_missing_prometheus_services
                         .where(projects: { id: start_id..stop_id })
                         .map(&method(:values_for_prometheus_service))

        insert_into_services(sql_values)
      end

      def values_for_prometheus_service(project)
        {
            project_id: project.id,
            active: true,
            properties: '{}',
            type: 'PrometheusService',
            template: false,
            push_events: true,
            issues_events: true,
            merge_requests_events: true,
            tag_push_events: true,
            note_events: true,
            category: 'monitoring',
            default: false,
            wiki_page_events: true,
            pipeline_events: true,
            confidential_issues_events: true,
            commit_events: true,
            job_events: true,
            confidential_note_events: true,
            deployment_events: false,
            created_at: 'NOW()',
            updated_at: 'NOW()'
        }
      end

      def insert_into_services(rows)
        Gitlab::Database.bulk_insert(Migratable::PrometheusService.table_name,
                                     rows,
                                     disable_quote: [:created_at, :updated_at])
      end
    end
  end
end
