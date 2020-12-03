# frozen_string_literal: true

module EE
  module ResourceAccessTokens
    module RevokeService
      include ::Gitlab::Allowable
      extend ::Gitlab::Utils::Override

      def execute
        super.tap do |response|
          log_audit_event(access_token, response)
        end
      end

      private

      def log_audit_event(access_token, response)
        return unless access_token.present?

        audit_event_service(access_token, response).for_user(full_path: access_token.user.username, entity_id: access_token.user.id).security_event
      end

      def audit_event_service(access_token, response)
        message = if response.success?
                    "Revoked project access token with id #{access_token.id}"
                  else
                    "Attempted to revoke project access token with id #{access_token.id} but failed with message: #{response.message}"
                  end

        ::AuditEventService.new(
          current_user,
          access_token.user,
          action: :custom,
          custom_message: message
        )
      end
    end
  end
end
