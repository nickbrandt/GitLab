# frozen_string_literal: true

class AddAssignedOpenIssuesCountToUser < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  COLUMN_NAME = :assigned_open_issues_count

  def up
    add_column :users, COLUMN_NAME, :integer
  end

  def down
    remove_column :users, COLUMN_NAME
  end
end
