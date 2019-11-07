# frozen_string_literal: true

module QA::EE
  module Page
    module Project
      module Settings
        class LicenseCompliance < QA::Page::Base
          include QA::Page::Component::Select2 # Select2 is an external library, so we can't add our own selectors

          view 'ee/app/assets/javascripts/vue_shared/license_management/license_management.vue' do
            element :license_add_button
          end

          view 'ee/app/assets/javascripts/vue_shared/license_management/components/add_license_form.vue' do
            element :license_radio, 'data-qa-selector="`${option.value}_license_radio`"' # rubocop:disable QA/ElementWithPattern
            element :add_license_submit_button
          end

          view 'ee/app/assets/javascripts/vue_shared/license_management/license_management.vue' do
            element :license_compliance_list
          end

          view 'ee/app/assets/javascripts/vue_shared/license_management/components/license_management_row.vue' do
            element :license_name_content
          end

          def approve_license(license)
            click_element :license_add_button
            expand_select_list
            search_and_select license
            click_element :approved_license_radio
            click_element :add_license_submit_button

            within_element :license_compliance_list do
              has_element?(:license_name_content, text: license)
            end
          end

          def deny_license(license)
            click_element :license_add_button
            expand_select_list
            search_and_select license
            click_element :blacklisted_license_radio
            click_element :add_license_submit_button

            within_element :license_compliance_list do
              has_element?(:license_name_content, text: license)
            end
          end
        end
      end
    end
  end
end
