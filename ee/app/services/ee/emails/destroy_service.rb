# frozen_string_literal: true

module EE
  module Emails
    module DestroyService
      extend ::Gitlab::Utils::Override
      include ::EE::Emails::BaseService # rubocop: disable Cop/InjectEnterpriseEditionModule

      override :execute
      def execute(email)
        super.tap do
          log_audit_event(action: :destroy)
        end
      end
    end
  end
end
