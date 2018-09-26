class AddNamespaceFileTemplateProjectId < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column :namespaces, :file_template_project_id, :integer
    add_concurrent_foreign_key :namespaces, :projects, column: :file_template_project_id, on_delete: :nullify
  end

  def down
    remove_foreign_key :namespaces, column: :file_template_project_id
    remove_column :namespaces, :file_template_project_id, :integer
  end
end
