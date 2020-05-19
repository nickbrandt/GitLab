# frozen_string_literal: true

module Gitlab
  module Auth
    module GroupSaml
      class MembershipUpdater
        attr_reader :user, :saml_provider

        delegate :group, to: :saml_provider

        def initialize(user, saml_provider)
          @user = user
          @saml_provider = saml_provider
        end

        def execute
          return if group.member?(@user)

          member = group.add_user(@user, default_membership_level)

          log_audit_event(member: member)
        end

        private

        def default_membership_level
          :guest
        end

        def log_audit_event(member:)
          ::AuditEventService.new(
            @user,
            member.source,
            action: :create
          ).for_member(member).security_event
        end
      end
    end
  end
end
