# frozen_string_literal: true
module GroupSaml
  module GroupManagedAccounts
    class CleanUpMembersService
      attr_reader :group, :current_user

      def initialize(current_user, group)
        @current_user = current_user
        @group = group
      end

      def execute
        non_group_managed_accounts.all? do |group_membership|
          membership = Members::DestroyService.new(current_user).execute(group_membership)
          membership.destroyed?
        end
      end

      private

      def non_group_managed_accounts
        @non_group_managed_accounts ||= GroupMembersFinder.new(group).not_managed
      end
    end
  end
end
