# frozen_string_literal: true

class AddUniqueConstraintOnDesignRegistryProjectId < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_design_registry_on_project_id'

  def change
    # `design_registry` is not in use yet, so no need to create index concurrently
    remove_index :design_registry, column: :project_id, name: INDEX_NAME # rubocop: disable Migration/RemoveIndex
    add_index    :design_registry,         :project_id, name: INDEX_NAME, unique: true # rubocop: disable Migration/AddIndex
  end
end
