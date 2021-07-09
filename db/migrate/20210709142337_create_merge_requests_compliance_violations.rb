class CreateMergeRequestsComplianceViolations < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    create_table :merge_requests_compliance_violations do |t|
      t.integer :reason, null: false
      t.bigint :violating_user_id, null: false
      t.bigint :merge_request_id, null: false
      t.index :reason
      t.index :violating_user_id
      t.index :merge_request_id
    end
  end

  def down
    drop_table :merge_requests_compliance_violations
  end
end
