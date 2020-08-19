# frozen_string_literal: true

class CreateIncidentData < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    unless table_exists?(:incident_data)
      create_table :incident_data do |t|
        t.timestamps_with_timezone null: false
        t.bigint :project_id, null: false, index: true
        t.bigint :issue_id, null: false, index: { unique: true }
        t.integer :severity, null: false, default: 0, limit: 2 # 0 - will stand for unknown
      end
    end
  end

  def down
    drop_table :incident_data
  end
end
