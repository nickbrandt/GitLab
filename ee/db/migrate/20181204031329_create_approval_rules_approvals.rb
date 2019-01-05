# frozen_string_literal: true

class CreateApprovalRulesApprovals < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table(:approval_merge_request_rules_approved_approvers, id: :bigserial) do |t|
      t.references(
        :approval_merge_request_rule,
        type: :bigint,
        null: false,
        foreign_key: { on_delete: :cascade },
        index: false
      )
      t.references(
        :user,
        type: :integer,
        null: false,
        foreign_key: { on_delete: :cascade },
        index: { name: 'index_approval_merge_request_rules_approved_approvers_2' }
      )

      t.index [:approval_merge_request_rule_id, :user_id], unique: true, name: 'index_approval_merge_request_rules_approved_approvers_1'
    end
  end
end
