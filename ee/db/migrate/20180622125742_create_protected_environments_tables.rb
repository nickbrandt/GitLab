class CreateProtectedEnvironmentsTables < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :protected_environments do |t|
      t.references :project, foreign_key: true, null: false, index: true
      t.string :name, null: false
      t.timestamps
    end

    add_index :protected_environments, [:project_id, :name], unique: true

    create_table :protected_environment_deploy_access_levels do |t|
      t.references :protected_environment, foreign_key: true, null: false
      t.integer :access_level, default: 40, null: false
      t.references :user, foreign_key: true
      t.timestamps
    end

    add_column :protected_environment_deploy_access_levels, :group_id, :integer
    add_foreign_key :protected_environment_deploy_access_levels, :namespaces, column: :group_id

    add_index :protected_environment_deploy_access_levels, [:protected_environment_id, :user_id], unique: true, name: "pro_env_dep_acc_lev_project_id_user_id"
    add_index :protected_environment_deploy_access_levels, [:protected_environment_id, :group_id], unique: true, name: "pro_env_dep_acc_lev_project_id_group_id"
  end
end
