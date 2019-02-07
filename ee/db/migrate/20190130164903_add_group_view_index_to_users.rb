# frozen_string_literal: true

class AddGroupViewIndexToUsers < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :users, :group_view
  end

  def down
    remove_concurrent_index :users, :group_view
  end
end
