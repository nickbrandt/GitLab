# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class PatchPrometheusServicesForSharedClusterApplications < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  MIGRATION = 'ActivatePrometheusServicesForSharedClusterApplications'.freeze
  BATCH_SIZE = 500
  DELAY = 2.minutes

  disable_ddl_transaction!

  module Migratable
    module Applications
      class Prometheus < ActiveRecord::Base
        self.table_name = 'clusters_applications_prometheus'

        enum status: {
          errored: -1,
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
          .where("services.id IS NULL OR (services.active = FALSE AND services.properties = '{}')")
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

    class PrometheusService < ActiveRecord::Base
      self.inheritance_column = :_type_disabled
      self.table_name = 'services'

      default_scope { where("services.type = 'PrometheusService'") }

      scope :managed, -> { where("services.properties = '{}'") }
      scope :not_active, -> { where.not("services.active") }
      scope :not_template, -> { where.not('services.template') }
      scope :join_applications, -> {
        joins('LEFT JOIN projects ON projects.id = services.project_id')
          .joins('LEFT JOIN namespaces ON namespaces.id = projects.namespace_id')
          .joins('LEFT JOIN cluster_groups ON cluster_groups.group_id = namespaces.id')
          .joins("LEFT JOIN clusters ON clusters.cluster_type = #{Cluster.cluster_types['instance_type']} OR
                            clusters.id = cluster_groups.cluster_id AND clusters.cluster_type = #{Cluster.cluster_types['group_type']}")
          .joins('LEFT JOIN clusters_applications_prometheus ON clusters_applications_prometheus.cluster_id = clusters.id')
      }
    end
  end

  def up
    projects_without_active_prometheus_service.group('projects.id').each_batch(of: BATCH_SIZE) do |batch, index|
      bg_migrations_batch = batch.select('projects.id').map { |project| [MIGRATION, project.id] }
      delay = index * DELAY
      BackgroundMigrationWorker.bulk_perform_in(delay.seconds, bg_migrations_batch)
    end
  end

  def down
    Migratable::PrometheusService.managed.not_template.not_active.delete_all
    Migratable::PrometheusService.managed.not_template.where(project_id: services_without_active_application.select('project_id')).delete_all
    clear_duplicates
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

  def services_without_active_application
    Migratable::PrometheusService
      .join_applications
      .managed
      .not_template
      .group('project_id')
      .having("NOT bool_or(COALESCE(clusters_applications_prometheus.status, #{Migratable::Applications::Prometheus.statuses[:errored]})
                IN (#{Migratable::Applications::Prometheus.statuses[:installed]}, #{Migratable::Applications::Prometheus.statuses[:updated]}))")
  end

  def clear_duplicates
    subquery = Migratable::PrometheusService.managed.not_template.select("id, ROW_NUMBER() OVER(PARTITION BY project_id ORDER BY project_id) AS row_num").to_sql
    duplicates_filter = "id in (SELECT id FROM (#{subquery}) t WHERE t.row_num > 1)"
    Migratable::PrometheusService.where(duplicates_filter).delete_all
  end
end
