# frozen_string_literal: true

module ApprovalRules
  class CreateService < ::ApprovalRules::BaseService
    include ::ApprovalRules::Updater

    # @param target [Project, MergeRequest]
    def initialize(target, user, params)
      @rule = target.approval_rules.build

      # report_approver rule_type is currently auto-set according to rulename
      # Techdebt to be addressed with: https://gitlab.com/gitlab-org/gitlab/issues/12759
      if target.is_a?(Project) && ApprovalProjectRule::REPORT_TYPES_BY_DEFAULT_NAME.key?(params[:name])
        params.reverse_merge!(rule_type: :report_approver)
      end

      handle_any_approver_rule_creation(target, params) if target.is_a?(Project)
      copy_approval_project_rule_properties(params) if target.is_a?(MergeRequest)

      super(@rule.project, user, params)
    end

    private

    def copy_approval_project_rule_properties(params)
      return if params[:approval_project_rule_id].blank?

      approval_project_rule = @rule.project.approval_rules.find_by_id(params[:approval_project_rule_id])

      return if approval_project_rule.blank?

      # Remove the following from params so when set they'll be ignored
      params.delete(:user_ids)
      params.delete(:group_ids)

      params[:name] = approval_project_rule.name
      params[:users] = approval_project_rule.users
      params[:groups] = approval_project_rule.groups
    end

    def handle_any_approver_rule_creation(target, params)
      if params[:user_ids].blank? && params[:group_ids].blank?
        params.reverse_merge!(rule_type: :any_approver, name: ApprovalRuleLike::ALL_MEMBERS)

        return
      end

      return if target.multiple_approval_rules_available?

      target.approval_rules.any_approver.delete_all
    end
  end
end
