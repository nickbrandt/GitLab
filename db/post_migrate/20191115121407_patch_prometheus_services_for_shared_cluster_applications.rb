# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class PatchPrometheusServicesForSharedClusterApplications < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers
  include Gitlab::Utils::StrongMemoize

  DOWNTIME = false
  MIGRATION = 'ActivatePrometheusServicesForSharedClusterApplications'.freeze
  BATCH_SIZE = 1_000
  DELAY = 2.minutes

  disable_ddl_transaction!

  module Migratable
    module Applications
      class Prometheus < ActiveRecord::Base
        self.table_name = 'clusters_applications_prometheus'
        enum status: {
          installed: 3,
          updated: 5
        }
      end
    end

    class Project < ActiveRecord::Base
      self.table_name = 'projects'
      include ::EachBatch

      scope :with_application_on_group_clusters, -> {
        joins("INNER JOIN namespaces ON namespaces.id = projects.namespace_id")
          .joins("INNER JOIN cluster_groups ON cluster_groups.group_id = namespaces.id")
          .joins("INNER JOIN clusters ON clusters.id = cluster_groups.cluster_id AND clusters.cluster_type = #{Cluster.cluster_types['group_type']}")
          .joins("INNER JOIN clusters_applications_prometheus ON clusters_applications_prometheus.cluster_id = clusters.id
                      AND clusters_applications_prometheus.status IN (#{Applications::Prometheus.statuses[:installed]}, #{Applications::Prometheus.statuses[:updated]})")
      }

      scope :without_active_prometheus_services, -> {
        joins("LEFT JOIN services ON services.project_id = projects.id AND services.type = 'PrometheusService'")
          .where("(services.id IS NULL OR (services.active = FALSE AND services.properties = '{}'))")
      }
    end

    class Cluster < ActiveRecord::Base
      self.table_name = 'clusters'

      enum cluster_type: {
        instance_type: 1,
        group_type: 2
      }

      def self.has_prometheus_application?
        joins("INNER JOIN clusters_applications_prometheus ON clusters_applications_prometheus.cluster_id = clusters.id
                   AND clusters_applications_prometheus.status IN (#{Applications::Prometheus.statuses[:installed]}, #{Applications::Prometheus.statuses[:updated]})").exists?
      end
    end
  end

  def up
    projects_without_active_prometheus_service.group('projects.id').each_batch(of: migrate_instance_cluster? ? BATCH_SIZE * 5 : BATCH_SIZE) do |batch, index|
      range = batch.pluck('projects.id')
      delay = index * DELAY
      BackgroundMigrationWorker.perform_in(delay.seconds, MIGRATION, range)
    end
  end

  def down
    # no-op
  end

  private

  def projects_without_active_prometheus_service
    scope = Migratable::Project
              .without_active_prometheus_services

    return scope if migrate_instance_cluster?

    scope.with_application_on_group_clusters
  end

  def migrate_instance_cluster?
    if instance_variable_defined?('@migrate_instance_cluster')
      @migrate_instance_cluster
    else
      @migrate_instance_cluster = Migratable::Cluster.instance_type.has_prometheus_application?
    end
  end
end
