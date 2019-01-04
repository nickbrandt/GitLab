# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class MigrateApproverToApprovalRulesInBatch
      class MergeRequest < ActiveRecord::Base
        self.table_name = 'merge_requests'
        include ::EachBatch
      end

      def perform(target_type, target_ids)
        target_ids.each do |target_id|
          MigrateApproverToApprovalRules.new.perform(target_type, target_id)
        end

        schedule_to_migrate_merge_requests(target_ids) if target_type == 'Project'
      end

      private

      def schedule_to_migrate_merge_requests(project_ids)
        jobs = []
        MergeRequest.where(target_project_id: project_ids).each_batch do |scope, _|
          jobs << [self.class.name, ['MergeRequest', scope.pluck(:id)]]
        end
        BackgroundMigrationWorker.bulk_perform_async(jobs) unless jobs.empty?
      end
    end
  end
end
