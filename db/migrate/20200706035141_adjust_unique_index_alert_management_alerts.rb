# frozen_string_literal: true

class AdjustUniqueIndexAlertManagementAlerts < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME        = false
  INDEX_NAME      = 'index_alert_management_alerts_on_project_id_and_fingerprint'
  RESOLVED_STATUS = AlertManagement::Alert::STATUSES[:resolved]

  # rubocop:disable Migration/RemoveIndex
  # rubocop:disable Migration/AddIndex
  def up
    remove_index :alert_management_alerts, name: INDEX_NAME
    add_index(:alert_management_alerts, %w(project_id fingerprint), where: "status <> '#{RESOLVED_STATUS}'", name: INDEX_NAME, unique: true, using: :btree)
  end

  def down
    remove_index :alert_management_alerts, name: INDEX_NAME
    add_index(:alert_management_alerts, %w(project_id fingerprint), name: INDEX_NAME, unique: true, using: :btree)
  end
  # rubocop:enable Migration/RemoveIndex
  # rubocop:enable Migration/AddIndex
end
