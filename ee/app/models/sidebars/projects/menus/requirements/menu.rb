# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      module Requirements
        class Menu < ::Sidebars::Menu
          override :link
          def link
            project_requirements_management_requirements_path(context.project)
          end

          override :configure_menu_items
          def configure_menu_items
            if Feature.disabled?(:project_sidebar_refactor, context.current_user)
              add_item(MenuItems::List.new(context))
            end
          end

          override :render?
          def render?
            can?(context.current_user, :read_requirement, context.project)
          end

          override :title
          def title
            _('Requirements')
          end

          override :sprite_icon
          def sprite_icon
            'requirements'
          end

          override :active_routes
          def active_routes
            { path: 'requirements#index' }
          end
        end
      end
    end
  end
end
