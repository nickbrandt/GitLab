# frozen_string_literal: true

module QA
  module EE
    module Page
      module Group
        class IssuesAnalytics < QA::Page::Base
          view 'ee/app/assets/javascripts/issues_analytics/components/issues_analytics.vue' do
            element :issues_analytics_graph
          end

          def graph
            find_element(:issues_analytics_graph)
          end
        end
      end
    end
  end
end
