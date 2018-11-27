# frozen_string_literal: true
class AddStateToEpic < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default :epics, :state, :integer, limit: 2, default: 1
  end

  def down
    remove_column :epics, :state
  end
end
