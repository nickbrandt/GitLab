# frozen_string_literal: true

class AddSectionToIndexOnApprovalMergeRequestRules < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  LEGACY_INDEX_NAME = "approval_rule_name_index_for_code_owners"
  SECTIONAL_INDEX_NAME = "approval_rule_name_index_for_sectional_code_owners"

  def up
    unless index_exists_by_name?(:approval_merge_request_rules, SECTIONAL_INDEX_NAME)
      add_concurrent_index(
        :approval_merge_request_rules,
        [:merge_request_id, :code_owner, :name, :section],
        unique: true,
        where: "(code_owner = true)",
        name: SECTIONAL_INDEX_NAME
      )
    end

    if index_exists_by_name?(:approval_merge_request_rules, LEGACY_INDEX_NAME)
      remove_concurrent_index_by_name :approval_merge_request_rules, LEGACY_INDEX_NAME
    end
  end

  def down
    unless index_exists_by_name?(:approval_merge_request_rules, LEGACY_INDEX_NAME)
      add_concurrent_index(
        :approval_merge_request_rules,
        [:merge_request_id, :code_owner, :name],
        unique: false,
        where: "(code_owner = true)",
        name: LEGACY_INDEX_NAME
      )
    end

    if index_exists_by_name?(:approval_merge_request_rules, SECTIONAL_INDEX_NAME)
      remove_concurrent_index_by_name :approval_merge_request_rules, SECTIONAL_INDEX_NAME
    end
  end
end
