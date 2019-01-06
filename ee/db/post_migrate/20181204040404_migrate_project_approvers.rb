# frozen_string_literal: true

class MigrateProjectApprovers < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  BATCH_SIZE = 1000

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

    bulk_queue_background_migration_jobs_by_range(MergeRequest, 'MigrateApproverToApprovalRulesInBatch')

    check_time = Gitlab::BackgroundMigration::MigrateApproverToApprovalRulesCheckProgress::RESCHEDULE_DELAY
    BackgroundMigrationWorker.bulk_perform_in(check_time, [['MigrateApproverToApprovalRulesCheckProgress']])
  end

  def down
  end

  private

  def get_project_ids
    project_ids = Approver.where('target_type = ?', 'Project').pluck(:target_id)
    project_ids += ApproverGroup.where('target_type = ?', 'Project').pluck(:target_id)
    project_ids.uniq!
    project_ids
  end
end
