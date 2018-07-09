# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddProtectedEnvironmentsTable < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :protected_environments do |t|
      t.timestamps_with_timezone null: false
      t.references :project, null: false, index: true, foreign_key: { on_delete: :cascade }
      t.string :name, null: false
    end

    add_index :protected_environments, [:project_id, :name], unique: true
  end
end
