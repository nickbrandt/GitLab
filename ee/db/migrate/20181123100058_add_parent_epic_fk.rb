# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.
class AddParentEpicFk < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :epics, :epics, column: :parent_id, on_delete: :cascade
    add_concurrent_index :epics, :parent_id
  end

  def down
    remove_foreign_key :epics, column: :parent_id
    remove_concurrent_index :epics, :parent_id
  end
end
