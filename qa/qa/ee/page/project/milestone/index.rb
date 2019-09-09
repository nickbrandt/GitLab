# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Milestone
          module Index
            def self.prepended(page)
              page.module_eval do
                view 'ee/app/views/shared/milestones/_weight.html.haml' do
                  element :total_issue_weight_value
                end
              end
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
