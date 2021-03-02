# frozen_string_literal: true

class DeleteInconsistentEpicIssueLinks < ActiveRecord::Migration[6.0]
  DOWNTIME = false
  BATCH_SIZE = 100

  class Epic < ActiveRecord::Base
    include ::EachBatch
    self.table_name = 'epics'

    has_many :epic_issues
    scope :with_issues, -> { joins(:epic_issues) }
  end

  class EpicIssue < ActiveRecord::Base
    self.table_name = 'epic_issues'
  end

  disable_ddl_transaction!

  def up
    return unless ::Gitlab.ee?

    Epic.with_issues.select('group_id').distinct.each_batch(of: BATCH_SIZE) do |batch|
      group_ids = batch.pluck(:group_id).join(',')
      delete_broken_epic_issue_links(group_ids)
    end
  end

  def down
    # no-op
  end

  private

  def delete_broken_epic_issue_links(group_ids)
    invalid_links = ApplicationRecord.connection.execute(<<-SQL.squish)
      SELECT epic_issues.* FROM epic_issues
      INNER JOIN epics ON epics.id = epic_issues.epic_id
      INNER JOIN issues ON issues.id = epic_issues.issue_id
      INNER JOIN projects ON projects.id = issues.project_id
      WHERE epics.group_id IN (#{group_ids})
        AND projects.namespace_id NOT IN (WITH RECURSIVE base_and_descendants AS (
          (SELECT namespaces.* FROM namespaces
            WHERE namespaces.type = 'Group'
            AND namespaces.id IN (#{group_ids}))
          UNION
          (SELECT namespaces.* FROM namespaces, base_and_descendants
            WHERE namespaces.type = 'Group'
            AND namespaces.parent_id = base_and_descendants.id))
          SELECT namespaces.id
          FROM base_and_descendants AS namespaces);
    SQL

    EpicIssue.where(id: invalid_links.pluck('id')).delete_all
  end
end
