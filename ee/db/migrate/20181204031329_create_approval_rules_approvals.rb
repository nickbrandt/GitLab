# frozen_string_literal: true

class CreateApprovalRulesApprovals < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table(:approval_merge_request_rules_approvals, id: :bigserial) do |t|
      t.references(
        :approval_merge_request_rule,
        type: :bigint,
        null: false,
        foreign_key: { on_delete: :cascade },
        index: false
      )
      t.references(
        :approval,
        type: :integer,
        null: false,
        foreign_key: { on_delete: :cascade },
        index: { name: 'index_approval_merge_request_rules_approvals_2' }
      )

      t.index [:approval_merge_request_rule_id, :approval_id], unique: true, name: 'index_approval_merge_request_rules_approvals_1'
    end
  end
end
