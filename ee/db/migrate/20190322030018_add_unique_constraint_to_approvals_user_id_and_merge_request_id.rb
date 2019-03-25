# frozen_string_literal: true

class AddUniqueConstraintToApprovalsUserIdAndMergeRequestId < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :approvals, [:user_id, :merge_request_id], unique: true
  end

  def down
    remove_concurrent_index :approvals, [:user_id, :merge_request_id]
  end
end
