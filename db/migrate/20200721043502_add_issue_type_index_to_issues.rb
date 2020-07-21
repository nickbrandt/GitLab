# frozen_string_literal: true

class AddIssueTypeIndexToIssues < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false
  disable_ddl_transaction!

  def up
    add_concurrent_index :issues, :issue_type
  end

  def down
    remove_concurrent_index :issues, :issue_type
  end
end
