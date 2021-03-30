# frozen_string_literal: true

class AddApprovalGroupsRulesGroups < ActiveRecord::Migration[6.0]
  INDEX_RULE_GROUP = 'idx_on_approval_group_rules_groups_rule_group'

  def up
    create_table :approval_group_rules_groups do |t|
      t.bigint :approval_group_rule_id, null: false
      t.bigint :group_id, null: false

      t.index [:approval_group_rule_id, :group_id], unique: true, name: INDEX_RULE_GROUP
    end
  end

  def down
    drop_table :approval_group_rules_groups
  end
end
