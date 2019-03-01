# frozen_string_literal: true

class AllowPrometheusAlertsPerEnvironment < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_METRIC_ENVIRONMENT_NAME = 'index_prometheus_alerts_metric_environment'

  disable_ddl_transaction!

  def up
    # Before we create the new index we need to remove it to deal with possible
    # failures from previous migration.
    #
    # See also https://gitlab.com/gitlab-org/gitlab-ce/issues/58164
    remove_concurrent_index :prometheus_alerts, INDEX_METRIC_ENVIRONMENT_NAME

    add_concurrent_index :prometheus_alerts, new_columns,
      name: INDEX_METRIC_ENVIRONMENT_NAME, unique: true

    remove_concurrent_index :prometheus_alerts, old_columns
  end

  def down
    delete_duplicate_alerts!

    # Before we create the new index we need to remove it to deal with possible
    # failures from previous migration.
    #
    # See also https://gitlab.com/gitlab-org/gitlab-ce/issues/58164
    remove_concurrent_index :prometheus_alerts, old_columns

    add_concurrent_index :prometheus_alerts, old_columns, unique: true

    remove_concurrent_index :prometheus_alerts, new_columns,
      name: INDEX_METRIC_ENVIRONMENT_NAME
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

  def new_columns
    [:project_id, :prometheus_metric_id, :environment_id]
  end

  def old_columns
    [:project_id, :prometheus_metric_id]
  end
end
