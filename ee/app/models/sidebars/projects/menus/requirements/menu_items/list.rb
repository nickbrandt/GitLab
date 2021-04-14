# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      module Requirements
        module MenuItems
          class List < ::Sidebars::MenuItem
            override :link
            def link
              project_requirements_management_requirements_path(context.project)
            end

            override :active_routes
            def active_routes
              { path: 'requirements#index' }
            end

            override :title
            def title
              _('List')
            end
          end
        end
      end
    end
  end
end
