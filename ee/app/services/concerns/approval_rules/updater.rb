# frozen_string_literal: true

module ApprovalRules
  module Updater
    def action
      filter_eligible_users!
      filter_eligible_groups!

      if rule.update(params)
        rule.reset
        success
      else
        error(rule.errors.messages)
      end
    end

    private

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
