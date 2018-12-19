# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class MigrateApproverToApprovalRulesCheckProgress
      RESCHEDULE_DELAY = 1.day

      def perform
        if remaining?
          BackgroundMigrationWorker.perform_in(RESCHEDULE_DELAY, self.class.name)
        else
          Feature.enable(:approval_rule)
        end
      end

      private

      def remaining?
        Gitlab::BackgroundMigration.exists?('MigrateApproverToApprovalRulesInBatch')
      end
    end
  end
end
