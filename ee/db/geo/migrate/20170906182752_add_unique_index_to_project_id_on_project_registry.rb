class AddUniqueIndexToProjectIdOnProjectRegistry < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    remove_concurrent_index :project_registry, :project_id if index_exists? :project_registry, :project_id
    # rubocop:disable Migration/ComplexIndexesRequireName
    add_concurrent_index :project_registry, :project_id, unique: true
    # rubocop:enable Migration/ComplexIndexesRequireName
  end

  def down
    remove_concurrent_index :project_registry, :project_id if index_exists? :project_registry, :project_id
    add_concurrent_index :project_registry, :project_id
  end
end
