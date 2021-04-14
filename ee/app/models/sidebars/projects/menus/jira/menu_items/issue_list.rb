# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      module Jira
        module MenuItems
          class IssueList < ::Sidebars::MenuItem
            override :link
            def link
              project_integrations_jira_issues_path(context.project)
            end

            override :active_routes
            def active_routes
              { path: 'projects/integrations/jira/issues#index' }
            end

            override :title
            def title
              s_('JiraService|Issue List')
            end
          end
        end
      end
    end
  end
end
