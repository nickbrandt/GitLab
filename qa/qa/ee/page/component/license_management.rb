# frozen_string_literal: true

module QA
  module EE
    module Page
      module Component
        module LicenseManagement
          def self.prepended(page)
            page.module_eval do
              view 'app/assets/javascripts/reports/components/report_item.vue' do
                element :report_item_row
              end

              view 'app/assets/javascripts/reports/components/issue_status_icon.vue' do
                element :icon_status, ':data-qa-selector="`status_${status}_icon`" ' # rubocop:disable QA/ElementWithPattern
              end

              view 'ee/app/assets/javascripts/vue_shared/license_management/components/set_approval_status_modal.vue' do
                element :license_management_modal
                element :approve_license_button
                element :blacklist_license_button
              end

              view 'ee/app/assets/javascripts/vue_shared/license_management/mr_widget_license_report.vue' do
                element :license_report_widget
              end
            end
          end

          def has_approved_license?(name)
            within_element(:report_item_row, text: name) do
              has_element?(:status_success_icon, wait: 1)
            end
          end

          def has_blacklisted_license?(name)
            within_element(:report_item_row, text: name) do
              has_element?(:status_failed_icon, wait: 1)
            end
          end

          def click_license(name)
            within_element(:license_report_widget) do
              click_on name
            end
            wait_for_animated_element(:license_management_modal)
          end

          def approve_license(name)
            click_license(name)
            click_element(:approve_license_button)
            wait_for_animated_element(:license_management_modal)
          end

          def blacklist_license(name)
            click_license(name)
            click_element(:blacklist_license_button)
            wait_for_animated_element(:license_management_modal)
          end
        end
      end
    end
  end
end
