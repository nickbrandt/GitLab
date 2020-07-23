# frozen_string_literal: true

class AddIssueTypeToIssues < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    with_lock_retries do
      # Set default to issue type
      add_column :issues, :issue_type, :integer, limit: 2, default: 0
    end
  end
end
