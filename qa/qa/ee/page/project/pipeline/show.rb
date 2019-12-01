# frozen_string_literal: true

module QA::EE
  module Page::Project
    module Pipeline
      module Show
        include Page::Component::LicenseManagement

        def self.prepended(page)
          page.module_eval do
            view 'ee/app/views/projects/pipelines/_tabs_holder.html.haml' do
              element :security_tab
              element :security_counter
              element :licenses_tab
              element :licenses_counter
            end

            view 'ee/app/assets/javascripts/security_dashboard/components/filter.vue' do
              element :filter_dropdown, ':data-qa-selector="qaSelector"' # rubocop:disable QA/ElementWithPattern
              element :filter_dropdown_content
            end

            view 'ee/app/views/projects/pipelines/_tabs_holder.html.haml' do
              element :security_tab
              element :security_counter
            end
          end
        end

        def click_on_security
          click_element(:security_tab)
        end

        def has_vulnerability_count_of?(count)
          find_element(:security_counter).has_content?(count)
        end

        def filter_report_type(report)
          click_element(:filter_report_type_dropdown)
          within_element(:filter_dropdown_content) do
            click_on report
          end
          # Click the dropdown to close the modal and ensure it isn't open if this function is called again
          click_element(:filter_report_type_dropdown)
        end

        def click_on_licenses
          click_element(:licenses_tab)
        end

        def has_license_count_of?(count)
          find_element(:licenses_counter).has_content?(count)
        end
      end
    end
  end
end
