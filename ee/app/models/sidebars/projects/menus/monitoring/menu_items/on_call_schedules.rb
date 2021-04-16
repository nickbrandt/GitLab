# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      module Monitoring
        module MenuItems
          class OnCallSchedules < ::Sidebars::MenuItem
            override :link
            def link
              project_incident_management_oncall_schedules_path(context.project)
            end

            override :active_routes
            def active_routes
              { controller: :oncall_schedules }
            end

            override :title
            def title
              _('On-call Schedules')
            end

            override :render?
            def render?
              can?(context.current_user, :read_incident_management_oncall_schedule, context.project)
            end
          end
        end
      end
    end
  end
end
