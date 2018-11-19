# frozen_string_literal: true

class CreateApprovalRules < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :approval_project_rules, id: :bigserial do |t|
      t.timestamps_with_timezone
      t.references :project, index: true, foreign_key: { on_delete: :cascade }, null: false
      t.integer :approvals_required, limit: 2, default: 0, null: false
      t.string :name, null: false
    end

    create_table :approval_merge_request_rules, id: :bigserial do |t|
      t.timestamps_with_timezone
      t.references :merge_request, index: true, foreign_key: { on_delete: :cascade }, null: false
      t.integer :approvals_required, limit: 2, default: 0, null: false
      t.boolean :code_owner, default: false, null: false
      t.string :name, null: false
    end
  end
end
