# frozen_string_literal: true

class RefreshLicenseComplianceChecksWorker
  include ApplicationWorker

  def perform(project_id)
    project = Project.find_by(id: project_id)
    return if project.nil?

    project_approval_rule = license_compliance_rule_for(project)
    return if project_approval_rule.nil?

    project.merge_requests.opened.find_each do |merge_request|
      merge_request_rule = license_compliance_rule_for(merge_request)
      next if merge_request_rule.nil?

      if merge_request.head_pipeline.license_management_report.violates?(project.software_license_policies)
        merge_request_rule.update!(approvals_required: project_approval_rule.approvals_required)
      else
      end
    end
  end

  private

  def license_compliance_rule_for(project)
    project
      .approval_rules
      .report_approver
      .find_by(name: ApprovalRuleLike::DEFAULT_NAME_FOR_LICENSE_REPORT)
  end
end
