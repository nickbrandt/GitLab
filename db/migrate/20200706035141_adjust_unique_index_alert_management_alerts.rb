# frozen_string_literal: true

class AdjustUniqueIndexAlertManagementAlerts < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME        = false
  INDEX_NAME      = 'index_alert_management_alerts_on_project_id_and_fingerprint'
  NEW_INDEX_NAME  = 'index_partial_am_alerts_on_project_id_and_fingerprint'
  RESOLVED_STATUS = 2

  # rubocop:disable Migration/RemoveIndex
  # rubocop:disable Migration/AddIndex
  def up
    add_index(:alert_management_alerts, %w(project_id fingerprint), where: "status <> '#{RESOLVED_STATUS}'", name: NEW_INDEX_NAME, unique: true, using: :btree)
    remove_index :alert_management_alerts, name: INDEX_NAME
  end

  def down
    # Nullify duplicate fingerprints, except for the newest of each match (project_id, fingerprint).
    query = <<-SQL
      UPDATE alert_management_alerts am
      SET fingerprint = NULL
      WHERE am.created_at <>
        (SELECT MAX(created_at)
        FROM alert_management_alerts am2
        WHERE am.fingerprint = am2.fingerprint AND am.project_id = am2.project_id)
      AND am.fingerprint IS NOT NULL;
    SQL

    execute(query)

    remove_index :alert_management_alerts, name: NEW_INDEX_NAME
    add_index(:alert_management_alerts, %w(project_id fingerprint), name: INDEX_NAME, unique: true, using: :btree)
  end
  # rubocop:enable Migration/RemoveIndex
  # rubocop:enable Migration/AddIndex
end
