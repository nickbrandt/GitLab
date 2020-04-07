# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemoveIndexCiGroupVariablesOnGroupIdAndKey < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :ci_group_variables,
                                    'index_ci_group_variables_on_group_id_and_key'
  end

  def down
    add_concurrent_index :ci_group_variables, [:group_id, :key],
                         unique: true,
                         using: :btree,
                         name: 'index_ci_group_variables_on_group_id_and_key'
  end
end
