# frozen_string_literal: true

module EE
  module Emails
    module CreateService
      extend ::Gitlab::Utils::Override
      include ::EE::Emails::BaseService # rubocop: disable Cop/InjectEnterpriseEditionModule

      override :execute
      def execute(extra_params = {})
        super.tap do |email|
          log_audit_event(action: :create) if email.persisted?
        end
      end
    end
  end
end
