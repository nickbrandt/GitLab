# frozen_string_literal: true

class SprintRenameStateToStateId < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    rename_column_concurrently :sprints, :state, :state_id
  end

  def down
    undo_rename_column_concurrently :sprints, :state, :state_id
  end
end
