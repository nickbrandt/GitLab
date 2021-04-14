# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      module Jira
        class Menu < ::Sidebars::Menu
          override :configure_menu_items
          def configure_menu_items
            add_item(::Sidebars::Projects::Menus::Jira::MenuItems::IssueList.new(context))
            add_item(::Sidebars::Projects::Menus::Jira::MenuItems::OpenJira.new(context))
          end

          override :link
          def link
            project_integrations_jira_issues_path(context.project)
          end

          override :title
          def title
            s_('JiraService|Jira Issues')
          end

          override :title_html_options
          def title_html_options
            {
              id: 'js-onboarding-settings-link'
            }
          end

          override :image_path
          def image_path
            'logos/jira-gray.svg'
          end

          # Hardcode sizes so image doesn't flash before CSS loads https://gitlab.com/gitlab-org/gitlab/-/issues/321022
          override :image_html_options
          def image_html_options
            {
              size: 16
            }
          end

          override :render?
          def render?
            context.project.external_issue_tracker &&
              context.project.external_issue_tracker.is_a?(JiraService) &&
              context.jira_issues_integration
          end
        end
      end
    end
  end
end
