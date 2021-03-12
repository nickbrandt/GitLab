# frozen_string_literal: true

module Gitlab
  module Audit
    module Levels
      class Group
        def initialize(group:)
          @group = group
        end

        def apply
          if Feature.enabled?(:audit_log_group_level, @group)
            projects = @group.all_projects

            AuditEvent.by_entity('Group', @group)
              .or(AuditEvent.by_entity('Project', projects))
          else
            AuditEvent.by_entity('Group', @group)
          end
        end
      end
    end
  end
end
