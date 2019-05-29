# frozen_string_literal: true

module EE
  module Members
    module DestroyService
      def after_execute(member:)
        super

        log_audit_event(member: member)

        cleanup_group_identity(member)
      end

      private

      def log_audit_event(member:)
        ::AuditEventService.new(
          current_user,
          member.source,
          action: :destroy
        ).for_member(member).security_event
      end

      def cleanup_group_identity(member)
        saml_provider = member.source.try(:saml_provider)

        return unless saml_provider

        saml_provider.identities.for_user(member.user).delete_all
      end
    end
  end
end
