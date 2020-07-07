# frozen_string_literal: true

class AddMrIndexToMergeRequestRules < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index(:approval_merge_request_rules, [:merge_request_id, :created_at], name: "mr_approval_rules_index")
  end

  def down
    remove_concurrent_index(:approval_merge_request_rules, [:merge_request_id, :created_at])
  end
end
