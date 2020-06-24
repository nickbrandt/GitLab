# frozen_string_literal: true

class RemoveGitlabIssueTrackerServiceRecords < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    execute <<~SQL.strip
      DELETE FROM services WHERE type = 'GitlabIssueTrackerService';
    SQL
  end

  def down
    # no-op
  end
end
