# frozen_string_literal: true

module EE
  module API
    module Releases
      extend ActiveSupport::Concern

      prepended do
        helpers do
          extend ::Gitlab::Utils::Override

          override :log_release_created_audit_event
          def log_release_created_audit_event(release)
            EE::AuditEvents::ReleaseCreatedAuditEventService.new(
              current_user,
              user_project,
              request.ip,
              release
            ).security_event
          end

          override :log_release_updated_audit_event
          def log_release_updated_audit_event
            EE::AuditEvents::ReleaseUpdatedAuditEventService.new(
              current_user,
              user_project,
              request.ip,
              release
            ).security_event
          end

          override :log_release_milestones_updated_audit_event
          def log_release_milestones_updated_audit_event
            EE::AuditEvents::ReleaseAssociateMilestoneAuditEventService.new(
              current_user,
              user_project,
              request.ip,
              release
            ).security_event
          end
        end
      end
    end
  end
end
