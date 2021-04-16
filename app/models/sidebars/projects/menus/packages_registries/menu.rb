# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      module PackagesRegistries
        class Menu < ::Sidebars::Menu
          override :configure_menu_items
          def configure_menu_items
            add_item(MenuItems::PackageRegistry.new(context))
            add_item(MenuItems::ContainerRegistry.new(context))
            add_item(MenuItems::InfrastructureRegistry.new(context))
          end

          override :link
          def link
            renderable_items.first.link
          end

          override :render?
          def render?
            has_renderable_items?
          end

          override :title
          def title
            _('Packages & Registries')
          end

          override :sprite_icon
          def sprite_icon
            'package'
          end
        end
      end
    end
  end
end
