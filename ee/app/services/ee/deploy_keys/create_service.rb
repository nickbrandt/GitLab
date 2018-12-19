# frozen_string_literal: true

module EE
  module DeployKeys
    module CreateService
      extend ::Gitlab::Utils::Override

      override :execute
      def execute(project: nil)
        super.tap do |key|
          if project && key.persisted?
            log_audit_event(key.title, project, action: :create)
          end
        end
      end

      private

      def log_audit_event(key_title, project, options = {})
        ::AuditEventService.new(user, project, options)
          .for_deploy_key(key_title).security_event
      end
    end
  end
end
