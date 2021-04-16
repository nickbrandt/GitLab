# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      module PackagesRegistries
        module MenuItems
          class InfrastructureRegistry < ::Sidebars::MenuItem
            override :link
            def link
              project_infrastructure_registry_index_path(context.project)
            end

            override :active_routes
            def active_routes
              { controller: :infrastructure_registry }
            end

            override :title
            def title
              _('Infrastructure Registry')
            end

            override :render?
            def render?
              Feature.enabled?(:infrastructure_registry_page, context.current_user)
            end
          end
        end
      end
    end
  end
end
