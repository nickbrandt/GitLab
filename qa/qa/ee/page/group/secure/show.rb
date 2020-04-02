# frozen_string_literal: true

module QA
  module EE
    module Page
      module Group
        module Secure
          class Show < QA::Page::Base
            include Page::Component::SecureReport

            view 'ee/app/assets/javascripts/security_dashboard/components/security_dashboard_table.vue' do
              element :security_report_content, required: true
            end

            def filter_project(project)
              click_element(:filter_project_dropdown)
              within_element(:filter_dropdown_content) do
                click_on project
              end
            end
          end
        end
      end
    end
  end
end
