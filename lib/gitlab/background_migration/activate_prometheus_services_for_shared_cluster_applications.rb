# frozen_string_literal: true
#
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class ActivatePrometheusServicesForSharedClusterApplications
      include Gitlab::Database::MigrationHelpers

      module Migratable
        class Applications::Prometheus < ActiveRecord::Base
          self.table_name = 'clusters_applications_prometheus'
          enum status: {
            installed: 3,
            updated: 5
          }
        end

        class Project < ActiveRecord::Base
          self.table_name = 'projects'

          def self.with_application_on_group_clusters
            joins("INNER JOIN namespaces ON namespaces.id = projects.namespace_id")
              .joins("INNER JOIN cluster_groups ON cluster_groups.group_id = namespaces.id")
              .joins("INNER JOIN clusters ON clusters.id = cluster_groups.cluster_id AND clusters.cluster_type = #{Cluster.cluster_types['group_type']}")
              .joins("INNER JOIN clusters_applications_prometheus ON clusters_applications_prometheus.cluster_id = clusters.id
                      AND clusters_applications_prometheus.status IN (#{Applications::Prometheus.statuses[:installed]}, #{Applications::Prometheus.statuses[:updated]})")
          end

          def self.with_missing_prometheus_services
            joins("LEFT JOIN services ON services.project_id = projects.id AND services.type = 'PrometheusService'")
              .where("services.id IS NULL")
          end
        end

        class Cluster < ActiveRecord::Base
          self.table_name = 'clusters'

          enum cluster_type: {
            instance_type: 1,
            group_type: 2,
            project_type: 3
          }

          def self.has_prometheus_application?
            joins("INNER JOIN clusters_applications_prometheus ON clusters_applications_prometheus.cluster_id = clusters.id
                   AND clusters_applications_prometheus.status IN (#{Applications::Prometheus.statuses[:installed]}, #{Applications::Prometheus.statuses[:updated]})").exists?
          end
        end

        class PrometheusService < ActiveRecord::Base
          self.table_name = 'services'

          def self.managed_inactive
            where("services.type = 'PrometheusService' AND services.active = FALSE AND services.properties = '{}'")
          end

          def self.with_project
            joins("INNER JOIN projects ON projects.id = services.project_id")
          end
        end
      end

      def perform(start_id, stop_id)
        ### Reactivate existing services which weren't configured manually
        prometheus_services_to_update(start_id, stop_id).update_all(active: true)
        ### create missing services
        insert_into_services(projects_with_missing_services(start_id, stop_id).map(&method(:values_for_prometheus_service)))
      end

      private

      def prometheus_services_to_update(start_id, stop_id)
        scope = Migratable::PrometheusService
          .managed_inactive
          .with_project
          .where(projects: { id: start_id..stop_id })

        return scope if migrate_instance_cluster?

        scope.merge(Migratable::Project.with_application_on_group_clusters)
      end

      def projects_with_missing_services(start_id, stop_id)
        scope = Migratable::Project
                    .with_missing_prometheus_services
                    .where(projects: { id: start_id..stop_id })

        return scope if migrate_instance_cluster?

        scope.with_application_on_group_clusters
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

      def migrate_instance_cluster?
        return @_migrate_instance_cluster if defined? @_migrate_instance_cluster

        @_migrate_instance_cluster = Migratable::Cluster.instance_type.has_prometheus_application?
      end
    end
  end
end
