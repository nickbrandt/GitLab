# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      module CiCd
        module MenuItems
          class PipelineEditor < ::Sidebars::MenuItem
            override :link
            def link
              project_ci_pipeline_editor_path(context.project)
            end

            override :active_routes
            def active_routes
              { path: 'projects/ci/pipeline_editor#show' }
            end

            override :title
            def title
              s_('Pipelines|Editor')
            end

            override :render?
            def render?
              context.can_view_pipeline_editor
            end
          end
        end
      end
    end
  end
end
