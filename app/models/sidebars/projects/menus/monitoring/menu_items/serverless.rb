# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      module Monitoring
        module MenuItems
          class Serverless < ::Sidebars::MenuItem
            override :link
            def link
              project_serverless_functions_path(context.project)
            end

            override :active_routes
            def active_routes
              { controller: :functions }
            end

            override :title
            def title
              _('Serverless')
            end

            override :render?
            def render?
              can?(context.current_user, :read_cluster, context.project)
            end
          end
        end
      end
    end
  end
end
