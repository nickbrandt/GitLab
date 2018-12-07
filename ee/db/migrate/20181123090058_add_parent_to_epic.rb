# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.
class AddParentToEpic < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column :epics, :parent_id, :integer unless parent_id_exists?
    add_concurrent_foreign_key :epics, :epics, column: :parent_id, on_delete: :cascade
    add_concurrent_index :epics, :parent_id
  end

  def down
    remove_foreign_key_without_error(:epics, column: :parent_id)
    remove_concurrent_index(:epics, :parent_id)
    remove_column(:epics, :parent_id) if parent_id_exists?
  end

  private

  def parent_id_exists?
    column_exists?(:epics, :parent_id)
  end
end
