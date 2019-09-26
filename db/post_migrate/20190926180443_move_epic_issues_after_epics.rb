# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class MoveEpicIssuesAfterEpics < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  BATCH_SIZE = 1_000

  disable_ddl_transaction!

  class Epic < ActiveRecord::Base
    self.table_name = 'epics'
  end

  class EpicIssue < ActiveRecord::Base
    self.table_name = 'epic_issues'

    include ::EachBatch
  end

  def up
    maximum_epic_position = Epic.maximum(:relative_position)

    return unless maximum_epic_position

    max_position = Gitlab::Database::MAX_INT_VALUE

    delta = ((maximum_epic_position - max_position) / 2.0).abs.ceil

    EpicIssue.where('relative_position < ?', maximum_epic_position).each_batch(of: BATCH_SIZE) do |batch, _|
      batch.update_all("relative_position = relative_position + #{delta}")
    end
  end

  def down
    # no need
  end
end
