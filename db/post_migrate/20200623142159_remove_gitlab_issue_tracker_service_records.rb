# frozen_string_literal: true

class RemoveGitlabIssueTrackerServiceRecords < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  disable_ddl_transaction!

  class Service < ActiveRecord::Base
    include EachBatch

    self.table_name = 'services'
  end

  class GitlabIssueTrackerService < Service
    def self.store_full_sti_class
      false
    end
  end

  def up
    while GitlabIssueTrackerService.any?
      execute <<~SQL.strip
        DELETE FROM services WHERE id IN (SELECT id FROM services WHERE type = 'GitlabIssueTrackerService' LIMIT 50)
      SQL
    end
  end

  def down
    # no-op
  end
end
