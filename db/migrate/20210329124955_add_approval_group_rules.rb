# frozen_string_literal: true

class AddApprovalGroupRules < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  INDEX_GROUP_ID_TYPE_NAME = 'idx_on_approval_group_rules_group_id_type_name'
  INDEX_ANY_APPROVER_TYPE = 'idx_on_approval_group_rules_any_approver_type'

  disable_ddl_transaction!

  def up
    create_table_with_constraints :approval_group_rules do |t|
      t.timestamps_with_timezone
      t.references :group, references: :namespaces, null: false,
                           foreign_key: { to_table: :namespaces, on_delete: :cascade }, index: false
      t.integer :approvals_required, limit: 2, null: false, default: 0
      t.integer :rule_type, limit: 2, null: false, default: 1
      t.text :name, null: false

      t.text_limit :name, 255
      t.index [:group_id, :rule_type, :name], unique: true, name: INDEX_GROUP_ID_TYPE_NAME
      t.index :id, where: 'rule_type = 4', name: INDEX_ANY_APPROVER_TYPE
    end
  end

  def down
    with_lock_retries do
      drop_table :approval_group_rules
    end
  end
end
