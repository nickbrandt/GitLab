class AddIndexToApprovalsMergeRequestId < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :approvals, :merge_request_id
  end

  def down
    remove_concurrent_index :approvals, :merge_request_id
  end
end
