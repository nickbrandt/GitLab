# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddProtectedEnvironmentDeployAccessLevelTable < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  GITLAB_ACCESS_MAINTAINER = 40

  disable_ddl_transaction!

  def up
    create_table :protected_environment_deploy_access_levels do |t|
      t.timestamps_with_timezone null: false
      t.references :protected_environment, index: { name: 'index_protected_environment_deploy_access' }, foreign_key: { on_delete: :cascade }, null: false
      t.references :user, foreign_key: { on_delete: :cascade }, index: true
      t.integer :access_level, default: GITLAB_ACCESS_MAINTAINER, null: false
      t.integer :group_id, index: true
    end

    add_concurrent_foreign_key :protected_environment_deploy_access_levels, :namespaces, column: :group_id
    add_index :protected_environment_deploy_access_levels, [:protected_environment_id, :user_id], unique: true, name: "pro_env_dep_acc_lev_project_id_user_id"
    add_index :protected_environment_deploy_access_levels, [:protected_environment_id, :group_id], unique: true, name: "pro_env_dep_acc_lev_project_id_group_id"
  end

  def down
    if foreign_keys_for(:protected_environment_deploy_access_levels, :group_id).any?
      remove_foreign_key :protected_environment_deploy_access_levels, column: :group_id
    end

    drop_table :protected_environment_deploy_access_levels
  end
end
