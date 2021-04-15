# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      module CiCd
        module MenuItems
          class Pipelines < ::Sidebars::MenuItem
            override :link
            def link
              project_pipelines_path(context.project)
            end

            override :extra_container_html_options
            def extra_container_html_options
              {
                class: 'shortcuts-pipelines'
              }
            end

            override :active_routes
            def active_routes
              { path: %w[
                  pipelines#index
                  pipelines#show
                  pipelines#new
                ]
              }
            end

            override :title
            def title
              _('Pipelines')
            end
          end
        end
      end
    end
  end
end
