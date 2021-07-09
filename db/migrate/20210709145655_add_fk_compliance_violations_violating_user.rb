# frozen_string_literal: true

class AddFkComplianceViolationsViolatingUser < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :merge_requests_compliance_violations,
                               :users,
                               column: :violating_user_id,
                               on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :merge_requests_compliance_violations, column: :violating_user_id
    end
  end
end
