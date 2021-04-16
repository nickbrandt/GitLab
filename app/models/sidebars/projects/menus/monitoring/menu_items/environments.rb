# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      module Monitoring
        module MenuItems
          class Environments < ::Sidebars::MenuItem
            override :link
            def link
              project_environments_path(context.project)
            end

            override :extra_container_html_options
            def extra_container_html_options
              {
                class: 'shortcuts-environments'
              }
            end

            override :active_routes
            def active_routes
              { controller: :environments }
            end

            override :title
            def title
              _('Environments')
            end

            override :render?
            def render?
              can?(context.current_user, :read_environment, context.project)
            end
          end
        end
      end
    end
  end
end
