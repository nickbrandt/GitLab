# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Milestone
          class Show < ::QA::Page::Base
            view 'ee/app/views/shared/milestones/_burndown.html.haml' do
              element :burndown_chart
            end

            view 'ee/app/views/shared/milestones/_weight.html.haml' do
              element :total_issue_weight_value
            end

            view 'ee/app/assets/javascripts/burndown_chart/components/burn_charts.vue' do
              element :weight_button
            end

            view 'ee/app/assets/javascripts/burndown_chart/components/burndown_chart.vue' do
              element :burndown_chart
            end

            def click_weight_button
              click_element(:weight_button)
            end

            def burndown_chart
              find_element(:burndown_chart)
            end

            def total_issue_weight_value
              find_element(:total_issue_weight_value)
            end
          end
        end
      end
    end
  end
end
