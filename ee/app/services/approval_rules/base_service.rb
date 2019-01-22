# frozen_string_literal: true

module ApprovalRules
  class BaseService < ::BaseService
    def execute
      return error(['Prohibited']) unless can_edit?

      filter_eligible_users!
      filter_eligible_groups!

      rule.attributes = params

      if rule.save
        success
      else
        error(rule.errors.messages)
      end
    end

    private

    attr_reader :rule

    def can_edit?
      can?(current_user, :edit_approval_rule, rule)
    end

    def success(*args, &blk)
      super.tap { |hsh| hsh[:rule] = rule }
    end

    def filter_eligible_users!
      return unless params.key?(:user_ids)

      params[:users] = project.members_among(User.id_in(params.delete(:user_ids)))
    end

    def filter_eligible_groups!
      return unless params.key?(:group_ids)

      params[:groups] = Group.id_in(params.delete(:group_ids)).public_or_visible_to_user(current_user)
    end
  end
end
