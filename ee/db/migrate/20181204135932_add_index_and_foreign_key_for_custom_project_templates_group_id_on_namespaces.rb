# frozen_string_literal: true

class AddIndexAndForeignKeyForCustomProjectTemplatesGroupIdOnNamespaces < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index(:namespaces, [:custom_project_templates_group_id, :type], where: "custom_project_templates_group_id IS NOT NULL")
    add_concurrent_foreign_key(:namespaces, :namespaces, column: :custom_project_templates_group_id, on_delete: :nullify)
  end

  def down
    # We need to remove the foreign key first, otherwise Mysql will fail with:
    # Mysql2::Error: Cannot drop index 'index_namespaces_on_custom_project_templates_group_id': needed in a foreign key constraint
    remove_foreign_key(:namespaces, column: :custom_project_templates_group_id)
    remove_concurrent_index(:namespaces, [:custom_project_templates_group_id, :type])
  end
end
