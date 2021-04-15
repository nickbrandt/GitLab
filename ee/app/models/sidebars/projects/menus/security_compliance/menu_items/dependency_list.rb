# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      module SecurityCompliance
        module MenuItems
          class DependencyList < ::Sidebars::MenuItem
            override :link
            def link
              project_dependencies_path(context.project)
            end

            override :extra_container_html_options
            def extra_container_html_options
              {
                data: { qa_selector: 'dependency_list_link' }
              }
            end

            override :active_routes
            def active_routes
              { path: 'projects/dependencies#index' }
            end

            override :title
            def title
              _('Dependency List')
            end

            override :render?
            def render?
              can?(context.current_user, :read_dependencies, context.project)
            end
          end
        end
      end
    end
  end
end
