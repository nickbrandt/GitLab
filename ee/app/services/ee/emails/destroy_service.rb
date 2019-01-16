# frozen_string_literal: true

module EE
  module Emails
    module DestroyService
      include ::EE::Emails::BaseService # rubocop: disable Cop/InjectEnterpriseEditionModule

      def execute(*args, &blk)
        super.tap do
          log_audit_event(action: :destroy)
        end
      end
    end
  end
end
