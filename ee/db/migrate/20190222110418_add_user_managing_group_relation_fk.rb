# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddUserManagingGroupRelationFk < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :users, :managing_group_id
    add_concurrent_foreign_key :users, :namespaces, column: :managing_group_id, on_delete: :nullify
  end

  def down
    remove_foreign_key :users, column: :managing_group_id
    remove_concurrent_index :users, :managing_group_id
  end
end
