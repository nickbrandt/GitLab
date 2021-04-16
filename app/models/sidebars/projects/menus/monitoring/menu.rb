# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      module Monitoring
        class Menu < ::Sidebars::Menu
          override :configure_menu_items
          def configure_menu_items
            add_item(MenuItems::MetricsDashboard.new(context))
            add_item(MenuItems::Logs.new(context))
            add_item(MenuItems::Tracing.new(context))
            add_item(MenuItems::ErrorTracking.new(context))
            add_item(MenuItems::AlertManagement.new(context))
            add_item(MenuItems::Incidents.new(context))
            add_item(MenuItems::Serverless.new(context))
            add_item(MenuItems::Terraform.new(context))
            add_item(MenuItems::Kubernetes.new(context))
            add_item(MenuItems::Environments.new(context))
            add_item(MenuItems::FeatureFlags.new(context))
            add_item(MenuItems::ProductAnalytics.new(context))
          end

          override :link
          def link
            if can?(context.current_user, :read_environment, context.project)
              metrics_project_environments_path(context.project)
            else
              project_feature_flags_path(context.project)
            end
          end

          override :extra_container_html_options
          def extra_container_html_options
            {
              class: 'shortcuts-operations'
            }
          end

          override :title
          def title
            _('Operations')
          end

          override :sprite_icon
          def sprite_icon
            'cloud-gear'
          end

          override :render?
          def render?
            context.project.feature_available?(:operations, context.current_user) && has_renderable_items?
          end

          override :active_routes
          def active_routes
            { controller: [:user, :gcp] }
          end
        end
      end
    end
  end
end

Sidebars::Projects::Menus::Monitoring::Menu.prepend_if_ee('EE::Sidebars::Projects::Menus::Monitoring::Menu')
