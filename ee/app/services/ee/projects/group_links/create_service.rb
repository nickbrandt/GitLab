# frozen_string_literal: true

module EE
  module Projects
    module GroupLinks
      module CreateService
        extend ::Gitlab::Utils::Override

        override :execute
        def execute(group)
          return error(error_message, 409) unless group_allowed_to_be_shared_with?(group)

          result = super

          log_audit_event(result[:link]) if result[:status] == :success
          result
        end

        private

        def group_allowed_to_be_shared_with?(group)
          return true unless project.root_ancestor.kind == 'group' && project.root_ancestor.enforced_sso?

          group.root_ancestor == project.root_ancestor
        end

        def error_message
          _('This group cannot be invited to a project inside a group with enforced SSO')
        end

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
