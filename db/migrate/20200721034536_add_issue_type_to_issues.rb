# frozen_string_literal: true

class AddIssueTypeToIssues < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    # Set default to issue type
    add_column :issues, :issue_type, :integer, limit: 2, default: 0
  end
end
