# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      module Monitoring
        module MenuItems
          class Tracing < ::Sidebars::MenuItem
            override :link
            def link
              project_tracing_path(context.project)
            end

            override :active_routes
            def active_routes
              { path: 'tracings#show' }
            end

            override :title
            def title
              _('Tracing')
            end

            override :render?
            def render?
              can?(context.current_user, :read_environment, context.project) &&
                can?(context.current_user, :admin_project, context.project)
            end
          end
        end
      end
    end
  end
end
