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
        destroy_non_gma_members && destroy_non_gma_identities
      end

      private

      def destroy_non_gma_members
        non_group_managed_accounts.all? do |group_membership|
          Members::DestroyService.new(current_user).execute(group_membership)
          group_membership.destroyed?
        end
      end

      def destroy_non_gma_identities
        non_group_managed_identities.all? do |identity|
          next true if group.has_owner?(identity.user)

          Identity::DestroyService.new(identity).execute
          identity.destroyed?
        end
      end

      def non_group_managed_accounts
        @non_group_managed_accounts ||= GroupMembersFinder.new(group).not_managed
      end

      def non_group_managed_identities
        @non_group_managed_identities ||= GroupSamlIdentityFinder.not_managed_identities(group: group)
      end
    end
  end
end
