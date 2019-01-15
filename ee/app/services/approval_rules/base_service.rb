# frozen_string_literal: true

module ApprovalRules
  class BaseService < ::BaseService
    private

    attr_reader :rule

    def can_edit?
      can?(current_user, :edit_approval_rule, rule)
    end

    def create_or_update
      return error(['Prohibited']) unless can_edit?

      filter_eligible_users
      filter_eligible_groups

      rule.attributes = params

      if rule.save
        success
      else
        error(rule.errors.messages)
      end
    end

    def success
      out = super()
      out[:rule] = rule
      out
    end

    def filter_eligible_users
      return unless params.key?(:user_ids)

      params[:users] = project.members_among(User.id_in(params[:user_ids]))
    end

    def filter_eligible_groups
      return unless params.key?(:group_ids)

      params[:groups] = Group.id_in(params[:group_ids]).public_or_visible_to_user(current_user)
    end
  end
end
