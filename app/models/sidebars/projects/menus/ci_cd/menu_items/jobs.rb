# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      module CiCd
        module MenuItems
          class Jobs < ::Sidebars::MenuItem
            override :link
            def link
              project_jobs_path(context.project)
            end

            override :extra_container_html_options
            def extra_container_html_options
              {
                class: 'shortcuts-builds'
              }
            end

            override :active_routes
            def active_routes
              { controller: :jobs }
            end

            override :title
            def title
              _('Jobs')
            end

            override :render?
            def render?
              can?(context.current_user, :read_build, context.project)
            end
          end
        end
      end
    end
  end
end
