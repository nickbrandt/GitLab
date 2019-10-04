# frozen_string_literal: true

module Security
  # Service for syncing security reports results to report_approver approval rules
  #
  class SyncReportsToApprovalRulesService < ::BaseService
    def initialize(pipeline)
      @pipeline = pipeline
    end

    def execute
      sync_license_management_rules
      sync_vulnerability_rules
      success
    rescue StandardError => error
      log_error(
        pipeline: pipeline&.to_param,
        error: error.class.name,
        message: error.message,
        source: "#{__FILE__}:#{__LINE__}",
        backtrace: error.backtrace
      )
      error("Failed to update approval rules")
    end

    private

    attr_reader :pipeline

    def sync_license_management_rules
      project = pipeline.project
      report = pipeline.license_scanning_report
      return if report.empty? && !pipeline.complete?
      return if report.violates?(project.software_license_policies)

      remove_required_approvals_for(ApprovalMergeRequestRule.report_approver.license_management)
    end

    def sync_vulnerability_rules
      reports = pipeline.security_reports.reports
      safe = reports.any? && reports.none? do |_report_type, report|
        report.unsafe_severity?
      end

      remove_required_approvals_for(ApprovalMergeRequestRule.security_report) if safe
    end

    def remove_required_approvals_for(rules)
      rules
        .for_unmerged_merge_requests(pipeline.merge_requests_as_head_pipeline)
        .update_all(approvals_required: 0)
    end
  end
end
