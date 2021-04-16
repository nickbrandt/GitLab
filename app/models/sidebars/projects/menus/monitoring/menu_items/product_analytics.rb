# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      module Monitoring
        module MenuItems
          class ProductAnalytics < ::Sidebars::MenuItem
            override :link
            def link
              project_product_analytics_path(context.project)
            end

            override :active_routes
            def active_routes
              { controller: :product_analytics }
            end

            override :title
            def title
              _('Product Analytics')
            end

            override :render?
            def render?
              Feature.enabled?(:product_analytics, context.project) &&
                can?(context.current_user, :read_product_analytics, context.project)
            end
          end
        end
      end
    end
  end
end
