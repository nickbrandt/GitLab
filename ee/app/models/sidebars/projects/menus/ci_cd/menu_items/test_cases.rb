# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      module CiCd
        module MenuItems
          class TestCases < ::Sidebars::MenuItem
            override :link
            def link
              project_quality_test_cases_path(context.project)
            end

            override :extra_container_html_options
            def extra_container_html_options
              {
                class: 'shortcuts-test-cases'
              }
            end

            override :active_routes
            def active_routes
              { controller: :test_cases }
            end

            override :title
            def title
              _('Test Cases')
            end

            override :render?
            def render?
              context.project.licensed_feature_available?(:quality_management) &&
                can?(context.current_user, :read_issue, context.project)
            end
          end
        end
      end
    end
  end
end
