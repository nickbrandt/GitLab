# frozen_string_literal: true

class AddDeployKeyTypeToKeys < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column :keys, :deploy_key_type, :integer, limit: 2, allow_null: true
  end

  def down
    remove_column :keys, :deploy_key_type
  end
end
