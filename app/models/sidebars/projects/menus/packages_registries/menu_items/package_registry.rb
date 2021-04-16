# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      module PackagesRegistries
        module MenuItems
          class PackageRegistry < ::Sidebars::MenuItem
            override :link
            def link
              project_packages_path(context.project)
            end

            override :active_routes
            def active_routes
              { controller: :packages }
            end

            override :title
            def title
              _('Package Registry')
            end

            override :render?
            def render?
              ::Gitlab.config.packages.enabled &&
                can?(context.current_user, :read_package, context.project)
            end
          end
        end
      end
    end
  end
end
