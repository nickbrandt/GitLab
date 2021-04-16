# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      module Monitoring
        module MenuItems
          class Kubernetes < ::Sidebars::MenuItem
            override :link
            def link
              project_clusters_path(context.project)
            end

            override :extra_container_html_options
            def extra_container_html_options
              {
                class: 'shortcuts-kubernetes'
              }
            end

            override :active_routes
            def active_routes
              { controller: [:cluster_agents, :clusters] }
            end

            override :title
            def title
              _('Kubernetes')
            end

            override :render?
            def render?
              can?(context.current_user, :read_cluster, context.project)
            end

            override :show_hint?
            def show_hint?
              context.show_cluster_hint
            end

            override :hint_html_options
            def hint_html_options
              { disabled: true,
                data: { trigger: 'manual',
                  container: 'body',
                  placement: 'right',
                  highlight: UserCalloutsHelper::GKE_CLUSTER_INTEGRATION,
                  highlight_priority: UserCallout.feature_names[:GKE_CLUSTER_INTEGRATION],
                  dismiss_endpoint: user_callouts_path,
                  auto_devops_help_path: help_page_path('topics/autodevops/index.md') } }
            end
          end
        end
      end
    end
  end
end
