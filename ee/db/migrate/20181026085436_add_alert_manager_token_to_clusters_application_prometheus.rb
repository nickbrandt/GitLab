# frozen_string_literal: true

class AddAlertManagerTokenToClustersApplicationPrometheus < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :clusters_applications_prometheus, :encrypted_alert_manager_token, :string
    add_column :clusters_applications_prometheus, :encrypted_alert_manager_token_iv, :string
  end
end
