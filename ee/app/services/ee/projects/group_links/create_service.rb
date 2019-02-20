# frozen_string_literal: true

module EE
  module Projects
    module GroupLinks
      module CreateService
        extend ::Gitlab::Utils::Override

        override :execute
        def execute(group)
          result = super

          log_audit_event(result[:link]) if result[:status] == :success
          result
        end

        private

        def log_audit_event(group_link)
          ::AuditEventService.new(
            current_user,
            group_link.group,
            action: :create
          ).for_project_group_link(group_link).security_event
        end
      end
    end
  end
end
