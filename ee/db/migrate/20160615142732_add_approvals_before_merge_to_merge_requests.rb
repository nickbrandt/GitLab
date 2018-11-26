class AddApprovalsBeforeMergeToMergeRequests < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  def change
    add_column :merge_requests, :approvals_before_merge, :integer
  end
end
