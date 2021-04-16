# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      module Monitoring
        module MenuItems
          class Incidents < ::Sidebars::MenuItem
            override :link
            def link
              project_incidents_path(context.project)
            end

            override :active_routes
            def active_routes
              { controller: [:incidents, :incident_management] }
            end

            override :title
            def title
              _('Incidents')
            end

            override :render?
            def render?
              can?(context.current_user, :read_issue, context.project)
            end
          end
        end
      end
    end
  end
end
