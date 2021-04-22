# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      module SecurityCompliance
        module MenuItems
          class AuditEvents < ::Sidebars::MenuItem
            override :link
            def link
              project_audit_events_path(context.project)
            end

            override :active_routes
            def active_routes
              { controller: :audit_events }
            end

            override :title
            def title
              _('Audit Events')
            end

            override :render?
            def render?
              can?(context.current_user, :read_project_audit_events, context.project) &&
                (context.project.licensed_feature_available?(:audit_events) || context.show_promotions)
            end
          end
        end
      end
    end
  end
end
