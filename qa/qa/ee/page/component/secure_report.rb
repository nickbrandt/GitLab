# frozen_string_literal: true

module QA
  module EE
    module Page
      module Component
        module SecureReport
          extend QA::Page::PageConcern

          def self.prepended(base)
            super

            base.class_eval do
              view 'ee/app/assets/javascripts/security_dashboard/components/filters/simple_filter.vue' do
                element :filter_dropdown, ':data-qa-selector="qaSelector"' # rubocop:disable QA/ElementWithPattern
                element :filter_dropdown_content
              end

              view 'ee/app/assets/javascripts/security_dashboard/components/security_dashboard_table_row.vue' do
                element :vulnerability_info_content
              end
            end
          end

          def filter_report_type(report)
            click_element(:filter_scanner_dropdown)

            click_element "filter_#{report.downcase.tr(" ", "_")}_dropdown"

            # Click the dropdown to close the modal and ensure it isn't open if this function is called again
            click_element(:filter_scanner_dropdown)
          end

          def has_vulnerability?(name)
            retry_until(reload: true, sleep_interval: 0.5) do
              has_element?(:vulnerability, text: name)
            end
          end

          def has_vulnerability_info_content?(name)
            has_element?(:vulnerability_info_content, text: name)
          end
        end
      end
    end
  end
end
