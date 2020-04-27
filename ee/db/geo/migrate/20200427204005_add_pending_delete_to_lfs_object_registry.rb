# frozen_string_literal: true

class AddPendingDeleteToLfsObjectRegistry < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:lfs_object_registry,
                            :pending_delete,
                            :boolean,
                            default: false,
                            allow_null: false)
  end

  def down
    remove_column(:lfs_object_registry, :pending_delete)
  end
end
