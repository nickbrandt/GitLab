# frozen_string_literal: true

module MergeRequests
  class SyncReportApproverApprovalRules
    def initialize(merge_request, params = {})
      @merge_request = merge_request
    end

    def execute
      if merge_request.target_project.feature_available?(:report_approver_rules)
        merge_request.synchronize_approval_rules_from_target_project
      end
    end

    private

    attr_reader :merge_request
  end
end
