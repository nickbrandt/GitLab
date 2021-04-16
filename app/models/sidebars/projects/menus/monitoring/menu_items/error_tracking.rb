# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      module Monitoring
        module MenuItems
          class ErrorTracking < ::Sidebars::MenuItem
            override :link
            def link
              project_error_tracking_index_path(context.project)
            end

            override :active_routes
            def active_routes
              { controller: :error_tracking }
            end

            override :title
            def title
              _('Error Tracking')
            end

            override :render?
            def render?
              can?(context.current_user, :read_sentry_issue, context.project)
            end
          end
        end
      end
    end
  end
end
