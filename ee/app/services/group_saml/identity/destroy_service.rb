# frozen_string_literal: true

module GroupSaml
  module Identity
    class DestroyService
      attr_reader :identity

      delegate :user, to: :identity

      def initialize(identity)
        @identity = identity
      end

      def execute
        identity.destroy!
        remove_group_access
      end

      private

      def remove_group_access
        return unless group_membership
        return if group.last_owner?(user)

        Members::DestroyService.new(user).execute(group_membership)
      end

      def group
        @group ||= identity.saml_provider.group
      end

      def group_membership
        @group_membership ||= group.group_member(user)
      end
    end
  end
end
