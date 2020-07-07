# frozen_string_literal: true

class AddRootAncestorToNamespaces < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :namespaces, :root_ancestor_id, :integer unless column_exists?(:namespaces, :root_ancestor_id)
    end

    add_concurrent_foreign_key :namespaces, :namespaces, column: :root_ancestor_id, on_delete: :restrict
    add_concurrent_index :namespaces, :root_ancestor_id
  end

  def down
    remove_concurrent_index :namespaces, :root_ancestor_id

    with_lock_retries do
      remove_column :namespaces, :root_ancestor_id
    end
  end
end
