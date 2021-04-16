# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      module Monitoring
        module MenuItems
          class Terraform < ::Sidebars::MenuItem
            override :link
            def link
              project_terraform_index_path(context.project)
            end

            override :active_routes
            def active_routes
              { controller: :terraform }
            end

            override :title
            def title
              _('Terraform')
            end

            override :render?
            def render?
              can?(context.current_user, :read_terraform_state, context.project)
            end
          end
        end
      end
    end
  end
end
