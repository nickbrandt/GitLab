# frozen_string_literal: true

class AddAlertQueryToPrometheusAlert < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :prometheus_alerts, :alert_query, :string, null: true # rubocop:disable Migration/AddLimitToStringColumns
  end
end
