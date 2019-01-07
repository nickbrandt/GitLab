# frozen_string_literal: true

class CreateApprovalMergeRequestRulesApprovalProjectRules < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table(:approval_merge_request_rule_sources, id: :bigserial) do |t|
      t.references(
        :approval_merge_request_rule,
        type: :bigint,
        null: false,
        foreign_key: { on_delete: :cascade },
        index: { name: 'index_approval_merge_request_rule_sources_1', unique: true }
      )
      t.references(
        :approval_project_rule,
        type: :bigint,
        null: false,
        foreign_key: { on_delete: :cascade },
        index: { name: 'index_approval_merge_request_rule_sources_2' }
      )
    end
  end
end
