# frozen_string_literal: true

class DeleteInconsistentEpicIssueLinks < ActiveRecord::Migration[6.0]
  DOWNTIME = false
  BATCH_SIZE = 1_000
  class EpicIssue < ActiveRecord::Base
    include ::EachBatch

    self.table_name = 'epic_issues'
    belongs_to :epic
    belongs_to :issue
  end

  def up
    return unless ::Gitlab.ee?

    Group.where(type: 'Group').joins(:epics).distinct.find_each do |group|
      delete_broken_epic_issue_links(group)
    end
  end

  def down
    # no-op
  end

  private

  def delete_broken_epic_issue_links(group)
    EpicIssue.joins(:epic).where(epics: { group_id: group })
      .joins(issue: :project).where.not(projects: { namespace_id: group.self_and_descendants })
      .each_batch(of: BATCH_SIZE) { |batch| batch.delete_all }
  end
end
