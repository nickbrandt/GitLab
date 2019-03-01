# frozen_string_literal: true

class CreateProjectIncidentManagementSettings < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :project_incident_management_settings, id: :int, primary_key: :project_id do |t|
      t.boolean :create_issue, default: false, null: false
      t.boolean :send_email, default: true, null: false
      t.text :issue_template_key
      t.foreign_key :projects, column: :project_id, on_delete: :cascade
    end
  end
end
