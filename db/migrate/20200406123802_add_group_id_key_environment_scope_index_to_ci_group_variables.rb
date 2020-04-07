# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddGroupIdKeyEnvironmentScopeIndexToCiGroupVariables < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_group_variables, [:group_id, :key, :environment_scope],
                         unique: true,
                         using: :btree,
                         name: 'index_ci_group_variables_on_group_id_key_environment_scope'
  end

  def down
    remove_concurrent_index_by_name :ci_group_variables,
                                    'index_ci_group_variables_on_group_id_key_environment_scope'
  end
end
