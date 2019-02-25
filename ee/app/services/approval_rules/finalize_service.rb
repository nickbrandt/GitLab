# frozen_string_literal: true

module ApprovalRules
  class FinalizeService
    attr_reader :merge_request

    def initialize(merge_request)
      @merge_request = merge_request
    end

    def execute
      return unless merge_request.merged?

      ActiveRecord::Base.transaction do
        if merge_request.approval_rules.regular.exists?
          merge_group_members_into_users
        else
          copy_project_approval_rules
        end

        merge_request.approval_rules.each(&:sync_approved_approvers)
      end
    end

    private

    def merge_group_members_into_users
      merge_request.approval_rules.each do |rule|
        rule.users += rule.group_users
      end
    end

    def copy_project_approval_rules
      merge_request.target_project.approval_rules.each do |project_rule|
        users = project_rule.approvers
        groups = project_rule.groups.public_or_visible_to_user(merge_request.author)

        merge_request.approval_rules.create!(
          project_rule.attributes.slice('approvals_required', 'name').merge(users: users, groups: groups)
        )
      end
    end
  end
end
