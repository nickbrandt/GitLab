# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      module Monitoring
        module MenuItems
          class MetricsDashboard < ::Sidebars::MenuItem
            override :link
            def link
              project_metrics_dashboard_path(context.project)
            end

            override :extra_container_html_options
            def extra_container_html_options
              {
                class: 'shortcuts-metrics'
              }
            end

            override :active_routes
            def active_routes
              { path: 'metrics_dashboard#show' }
            end

            override :title
            def title
              _('Metrics')
            end

            override :render?
            def render?
              can?(context.current_user, :metrics_dashboard, context.project)
            end
          end
        end
      end
    end
  end
end
