# frozen_string_literal: true

class AddIndexToNameOnApprovalMergeRequestRules < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  disable_ddl_transaction!

  INDEX_NAME = 'approval_rule_name_index_for_code_owners'

  def up
    add_concurrent_index(
      :approval_merge_request_rules,
      [:merge_request_id, :code_owner, :name],
      unique: true,
      where: "code_owner = 't'",
      name: INDEX_NAME
    )
  end

  def down
    remove_concurrent_index(
      :approval_merge_request_rules,
      [:merge_request_id, :name],
      name: INDEX_NAME
    )
  end
end
