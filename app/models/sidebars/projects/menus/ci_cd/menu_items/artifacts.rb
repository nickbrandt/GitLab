# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      module CiCd
        module MenuItems
          class Artifacts < ::Sidebars::MenuItem
            override :link
            def link
              project_artifacts_path(context.project)
            end

            override :extra_container_html_options
            def extra_container_html_options
              {
                class: 'shortcuts-builds'
              }
            end

            override :active_routes
            def active_routes
              { path: 'artifacts#index' }
            end

            override :title
            def title
              _('Artifacts')
            end

            override :render?
            def render?
              Feature.enabled?(:artifacts_management_page, context.project)
            end
          end
        end
      end
    end
  end
end
