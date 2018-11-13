# frozen_string_literal: true

class CreateUsersOpsDashboardProjects < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :users_ops_dashboard_projects, id: :bigserial do |t|
      t.timestamps_with_timezone null: false
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.references :project, index: true, foreign_key: { on_delete: :cascade }, null: false

      t.index [:user_id, :project_id], unique: true
    end
  end
end
