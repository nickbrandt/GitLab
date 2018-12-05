# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class MigrateApproverToApprovalRulesInBatch
      def perform(target_type, target_ids)
        target_ids.each do |target_id|
          MigrateApproverToApprovalRules.new.perform(target_type, target_id)
        end
      end
    end
  end
end
