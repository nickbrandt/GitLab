# frozen_string_literal: true

module QA::EE::Page
  module Project::Pipeline
    module Show
      def self.prepended(page)
        page.module_eval do
          view 'ee/app/views/projects/pipelines/_tabs_holder.html.haml' do
            element :security_tab
          end

          view 'ee/app/assets/javascripts/vue_shared/security_reports/split_security_reports_app.vue' do
            element :dependency_scanning_report
          end

          view 'app/assets/javascripts/reports/components/report_section.vue' do
            element :expand_report_button
          end
        end
      end

      def click_on_security
        click_element(:security_tab)
      end

      def has_dependency_report?
        find_element(:dependency_scanning_report)
      end

      def expand_dependency_report
        within_element(:dependency_scanning_report) do
          click_element(:expand_report_button)
        end
      end
    end
  end
end
