# frozen_string_literal: true

module EE
  module Groups
    module CreateService
      extend ::Gitlab::Utils::Override

      override :execute
      def execute
        super.tap { |group| log_audit_event if group&.persisted? }
      end

      private

      override :after_build_hook
      def after_build_hook(group, params)
        # Repository size limit comes as MB from the view
        limit = params.delete(:repository_size_limit)
        group.repository_size_limit = ::Gitlab::Utils.try_megabytes_to_bytes(limit) if limit
      end

      def log_audit_event
        ::AuditEventService.new(
          current_user,
          group,
          action: :create
        ).for_group.security_event
      end
    end
  end
end
