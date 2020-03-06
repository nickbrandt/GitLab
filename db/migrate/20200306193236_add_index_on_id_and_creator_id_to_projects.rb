# frozen_string_literal: true

class AddIndexOnIdAndCreatorIdToProjects < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :projects, [:id, :creator_id]
  end

  def down
    remove_concurrent_index :projects, [:id, :creator_id]
  end
end
