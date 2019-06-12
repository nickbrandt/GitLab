# frozen_string_literal: true

module ApprovalRules
  class CopyToMergeRequestService < ::ApprovalRules::BaseService
    def initialize(merge_request, user)
      @merge_request = merge_request

      super(merge_request.project, user)
    end

    def execute
      if @merge_request.approval_state.approval_rules_overwritten?
        return error("Approval rule has already been overwritten")
      end

      rules = @merge_request.project.approval_rules.regular.to_a

      success if rules.blank?

      rules.map! do |rule|
        {
          name: rule.name,
          user_ids: rule.users.map(&:id),
          group_ids: rule.groups.map(&:id),
          approvals_required: rule.approvals_required,
          code_owner: false,
          rule_type: :regular,
          approval_project_rule_id: rule.id
        }
      end

      @merge_request.update!(approval_rules_attributes: rules)

      success
    end
  end
end
