# frozen_string_literal: true

class ChangeColumnNullTestReportRequirement < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    with_lock_retries do
      change_column_null :requirements_management_test_reports, :requirement_id, true
    end

    add_concurrent_foreign_key :requirements_management_test_reports, :issues, column: :issue_id
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists(:requirements_management_test_reports, column: :issue_id)
    end

    with_lock_retries do
      change_column_null :requirements_management_test_reports, :requirement_id, false
    end
  end
end
