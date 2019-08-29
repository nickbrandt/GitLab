# frozen_string_literal: true

class RefreshLicenseComplianceChecksWorker
  include ApplicationWorker

  def perform(project_id)
    project = Project.find_by(id: project_id)
    return if project.nil?

    project_approval_rule = license_compliance_rule_for(project)
    return if project_approval_rule.nil?

    merge_requests_for(project).find_each do |merge_request|
      license_compliance_rule_for(merge_request)&.refresh_required_approvals!(project_approval_rule)
    end
  end

  private

  def merge_requests_for(project)
    project
      .merge_requests
      .opened
      .includes(:approval_rules, :head_pipeline)
      .where(approval_merge_request_rules: {
        name: ApprovalRuleLike::DEFAULT_NAME_FOR_LICENSE_REPORT,
        rule_type: ApprovalMergeRequestRule.rule_types[:report_approver]
      })
  end

  def license_compliance_rule_for(target)
    rule_for(target: target, name: ApprovalRuleLike::DEFAULT_NAME_FOR_LICENSE_REPORT)
  end

  def rule_for(target:, name:)
    target
      .approval_rules
      .report_approver
      .find_by(name: name)
  end
end
