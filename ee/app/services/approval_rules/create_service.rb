# frozen_string_literal: true

module ApprovalRules
  class CreateService < ::ApprovalRules::BaseService
    # @param target [Project, MergeRequest]
    def initialize(target, user, params)
      @rule = target.approval_rules.build

      # report_approver rule_type is currently auto-set according to rulename
      # Techdebt to be addressed with: https://gitlab.com/gitlab-org/gitlab-ee/issues/12759
      if target.is_a?(Project) && params[:name] == ApprovalProjectRule::DEFAULT_NAME_FOR_SECURITY_REPORT
        params.reverse_merge!(rule_type: :report_approver)
      end

      super(@rule.project, user, params)
    end
  end
end
