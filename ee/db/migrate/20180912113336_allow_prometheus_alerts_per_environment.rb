# frozen_string_literal: true

class AllowPrometheusAlertsPerEnvironment < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_METRIC_ENVIRONMENT_NAME = 'index_prometheus_alerts_metric_environment'

  disable_ddl_transaction!

  def up
    rebuild_foreign_key do
      # Before we create the new index we need to remove it to deal with possible
      # failures from previous migration.
      #
      # See also https://gitlab.com/gitlab-org/gitlab-ce/issues/58164
      remove_concurrent_index :prometheus_alerts, INDEX_METRIC_ENVIRONMENT_NAME

      add_concurrent_index :prometheus_alerts, new_columns,
        name: INDEX_METRIC_ENVIRONMENT_NAME, unique: true

      remove_concurrent_index :prometheus_alerts, old_columns
    end
  end

  def down
    delete_duplicate_alerts!

    rebuild_foreign_key do
      # Before we create the new index we need to remove it to deal with possible
      # failures from previous migration.
      #
      # See also https://gitlab.com/gitlab-org/gitlab-ce/issues/58164
      remove_concurrent_index :prometheus_alerts, old_columns

      add_concurrent_index :prometheus_alerts, old_columns, unique: true

      remove_concurrent_index :prometheus_alerts, new_columns,
        name: INDEX_METRIC_ENVIRONMENT_NAME
    end
  end

  private

  class PrometheusAlert < ActiveRecord::Base
    include ::EachBatch
  end

  # Before adding a more narrow index again we need to make sure to delete
  # newest "duplicate" alerts and keep only the oldest alert per project and metric.
  def delete_duplicate_alerts!
    duplicate_alerts = PrometheusAlert
      .select('MIN(id) AS min, COUNT(id), project_id')
      .group(:project_id)
      .having('COUNT(id) > 1')

    duplicate_alerts.each do |alert|
      PrometheusAlert
        .where(project_id: alert['project_id'])
        .where('id <> ?', alert['min'])
        .each_batch { |batch| batch.delete_all }
    end
  end

  # MySQL requires to drop FK for time of re-adding index
  def rebuild_foreign_key
    if Gitlab::Database.mysql?
      remove_foreign_key_without_error :prometheus_alerts, :prometheus_metrics
      remove_foreign_key_without_error :prometheus_alerts, :projects
    end

    yield

    if Gitlab::Database.mysql?
      add_concurrent_foreign_key :prometheus_alerts, :prometheus_metrics,
        column: :prometheus_metric_id, on_delete: :cascade
      add_concurrent_foreign_key :prometheus_alerts, :projects,
        column: :project_id, on_delete: :cascade
    end
  end

  def new_columns
    [:project_id, :prometheus_metric_id, :environment_id]
  end

  def old_columns
    [:project_id, :prometheus_metric_id]
  end
end
