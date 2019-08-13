# frozen_string_literal: true

module MergeRequests
  class SyncReportApproverApprovalRules
    def initialize(merge_request, params = {})
      @merge_request = merge_request
    end

    def execute
      if merge_request.target_project.feature_available?(:report_approver_rules)
        sync_rules
      end
    end

    private

    attr_reader :merge_request

    def sync_rules
      return if merge_request.merged?

      sync_project_approval_rules_to_merge_request_rules
    end

    def sync_project_approval_rules_to_merge_request_rules
      merge_request.target_project.approval_rules.report_approver.each do |project_rule|
        merge_request.approval_rules.report_approver.first_or_initialize.tap do |rule|
          rule.update(attributes_from(project_rule))
        end
      end
    end

    def attributes_from(project_rule)
      project_rule.attributes
       .slice('approvals_required', 'name')
       .merge(
         users: project_rule.users,
         groups: project_rule.groups,
         approval_project_rule: project_rule,
         rule_type: :report_approver,
         report_type: :security
       )
    end
  end
end
