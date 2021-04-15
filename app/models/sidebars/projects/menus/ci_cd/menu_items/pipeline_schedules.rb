# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      module CiCd
        module MenuItems
          class PipelineSchedules < ::Sidebars::MenuItem
            override :link
            def link
              pipeline_schedules_path(context.project)
            end

            override :extra_container_html_options
            def extra_container_html_options
              {
                class: 'shortcuts-builds'
              }
            end

            override :active_routes
            def active_routes
              { controller: :pipeline_schedules }
            end

            override :title
            def title
              _('Schedules')
            end
          end
        end
      end
    end
  end
end
