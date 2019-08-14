# frozen_string_literal: true

module Gitlab
  module IpRestriction
    class Enforcer
      def initialize(group)
        @group = group
      end

      def allows_current_ip?
        return true unless group&.feature_available?(:group_ip_restriction)

        current_ip_address = Gitlab::IpAddressState.current

        return true unless current_ip_address

        allows_address?(current_ip_address)
      end

      private

      attr_reader :group

      def allows_address?(address)
        root_ancestor_ip_restrictions = group.root_ancestor_ip_restrictions

        return true unless root_ancestor_ip_restrictions.present?

        root_ancestor_ip_restrictions.any? { |ip_restriction| ip_restriction.allows_address?(address) }
      end
    end
  end
end
