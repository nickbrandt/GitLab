# frozen_string_literal: true

module Security
  # Service for syncing security reports results to report_approver approval rules
  #
  class SyncReportsToApprovalRulesService < ::BaseService
    def initialize(pipeline)
      @pipeline = pipeline
    end

    def execute
      reports = @pipeline.security_reports.reports

      safe = reports.any? && reports.none? do |_report_type, report|
        report.unsafe_severity?
      end

      return success unless safe

      if remove_required_report_approvals(@pipeline.merge_requests_as_head_pipeline)
        success
      else
        error("Failed to update approval rules")
      end
    end

    private

    def remove_required_report_approvals(merge_requests)
      ApprovalMergeRequestRule
        .security_report
        .for_unmerged_merge_requests(merge_requests)
        .update_all(approvals_required: 0)
    end
  end
end
