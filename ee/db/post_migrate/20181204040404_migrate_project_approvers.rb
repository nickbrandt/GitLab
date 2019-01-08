# frozen_string_literal: true

class MigrateProjectApprovers < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  BATCH_SIZE = 3000

  class MergeRequest < ActiveRecord::Base
    include ::EachBatch
    self.table_name = 'merge_requests'
  end

  class Approver < ActiveRecord::Base
    self.table_name = 'approvers'
  end

  class ApproverGroup < ActiveRecord::Base
    self.table_name = 'approver_groups'
  end

  def up
    get_project_ids.each do |project_id|
      Gitlab::BackgroundMigration::MigrateApproverToApprovalRules.new.perform('Project', project_id)
    end

    bulk_queue_background_migration_jobs_by_range(MergeRequest, 'MigrateApproverToApprovalRulesInBatch', batch_size: BATCH_SIZE)

    check_time = Gitlab::BackgroundMigration::MigrateApproverToApprovalRulesCheckProgress::RESCHEDULE_DELAY
    BackgroundMigrationWorker.bulk_perform_in(check_time, [['MigrateApproverToApprovalRulesCheckProgress']])
  end

  def down
  end

  private

  def get_project_ids
    results = ActiveRecord::Base.connection.exec_query <<~SQL
      SELECT DISTINCT target_id FROM (
        SELECT target_id FROM approvers WHERE target_type='Project'
        UNION
        SELECT target_id FROM approver_groups WHERE target_type='Project'
      ) t
    SQL

    results.rows.flatten
  end
end
