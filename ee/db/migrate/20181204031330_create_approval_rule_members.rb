# frozen_string_literal: true

class CreateApprovalRuleMembers < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  TABLES = [
    { table: 'approval_merge_request_rules_users',  rule: 'approval_merge_request_rule', member: 'user',  member_table: 'users' },
    { table: 'approval_merge_request_rules_groups', rule: 'approval_merge_request_rule', member: 'group', member_table: 'namespaces' },
    { table: 'approval_project_rules_users',        rule: 'approval_project_rule',       member: 'user',  member_table: 'users' },
    { table: 'approval_project_rules_groups',       rule: 'approval_project_rule',       member: 'group', member_table: 'namespaces' }
  ].freeze

  def up
    TABLES.each do |params|
      member_id = "#{params[:member]}_id"
      rule_id = "#{params[:rule]}_id"

      create_table(params[:table], id: :bigserial) do |t|
        t.references params[:rule],   null: false, type: :bigint,  index: false, foreign_key: { on_delete: :cascade }
        t.references params[:member], null: false, type: :integer, index: { name: "index_#{params[:table]}_2" }

        # To accommodate Group being in the `namespaces` table
        t.foreign_key params[:member_table], column: member_id, on_delete: :cascade

        t.index [rule_id, member_id], unique: true, name: "index_#{params[:table]}_1"
      end
    end
  end

  def down
    TABLES.each { |params| drop_table(params[:table]) }
  end
end
