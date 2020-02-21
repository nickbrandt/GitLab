# frozen_string_literal: true

class AddUniqueIndexesOnServices < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :services, [:type, :project_id], unique: true, where: 'project_id IS NOT NULL'
  end

  def down
    remove_concurrent_index :services, [:type, :project_id]
  end
end
