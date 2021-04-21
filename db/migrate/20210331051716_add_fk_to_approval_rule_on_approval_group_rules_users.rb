# frozen_string_literal: true

class AddFkToApprovalRuleOnApprovalGroupRulesUsers < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :approval_group_rules_users, :approval_group_rules, column: :approval_group_rule_id,
                                                                                   on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :approval_group_rules_users, column: :approval_group_rule_id
    end
  end
end
