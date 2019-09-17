# frozen_string_literal: true

module EE
  module ProtectedBranches
    module UpdateService
      extend ::Gitlab::Utils::Override
      include Loggable

      override :execute
      def execute(protected_branch)
        super(protected_branch).tap do |protected_branch_service|
          log_audit_event(protected_branch_service, :update)
        end
      end
    end
  end
end
