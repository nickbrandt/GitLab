# frozen_string_literal: true

class DeleteInconsistentEpicIssueLinks < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 50
  MIGRATION = 'RemoveInaccessibleEpicIssueLinks'

  disable_ddl_transaction!

  class Epic < ActiveRecord::Base
    include EachBatch

    self.table_name = 'epics'
    has_many :epic_issues
    scope :with_issues, -> { joins(:epic_issues) }
  end

  def up
    return unless run_migration?

    Epic.reset_column_information
    Epic.with_issues.select('group_id').distinct.each_batch(of: BATCH_SIZE, column: 'group_id') do |group_batch, index|
      group_ids = group_batch.pluck(:group_id)
      migrate_in(index * DELAY_INTERVAL, MIGRATION, group_ids)
    end
  end

  def down
    # no-op
  end

  def run_migration?
    Gitlab.ee? && table_exists?(:epics) && table_exists?(:epic_issues)
  end
end
