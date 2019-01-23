# frozen_string_literal: true

module EE
  module MergeRequests
    module BaseService
      private

      def filter_params(merge_request)
        unless current_user.can?(:update_approvers, merge_request)
          params.delete(:approvals_before_merge)
          params.delete(:approver_ids)
          params.delete(:approver_group_ids)
        end

        filter_approval_rule_groups_and_users(merge_request)

        super
      end

      def filter_approval_rule_groups_and_users(merge_request)
        return unless params.key?(:approval_rules_attributes)

        group_ids = params[:approval_rules_attributes].flat_map { |hash| hash[:group_ids] }
        user_ids = params[:approval_rules_attributes].flat_map { |hash| hash[:user_ids] }

        # rubocop: disable CodeReuse/ActiveRecord
        group_ids = ::Group.id_in(group_ids).public_or_visible_to_user(current_user).pluck(:id) unless group_ids.empty?
        user_ids = merge_request.project.members_among(::User.id_in(user_ids)).pluck(:id) unless user_ids.empty?
        # rubocop: enable CodeReuse/ActiveRecord

        params[:approval_rules_attributes].each do |rule_attributes|
          if rule_attributes.key?(:group_ids)
            provided_group_ids = rule_attributes[:group_ids].map(&:to_i)
            rule_attributes[:group_ids] = provided_group_ids & group_ids
          end

          if rule_attributes.key?(:user_ids)
            provided_user_ids = rule_attributes[:user_ids].map(&:to_i)
            rule_attributes[:user_ids] = provided_user_ids & user_ids
          end
        end
      end
    end
  end
end
