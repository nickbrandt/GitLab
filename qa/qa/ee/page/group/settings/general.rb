# frozen_string_literal: true

module QA
  module EE
    module Page
      module Group
        module Settings
          class General < QA::Page::Base
            include ::QA::Page::Component::Select2
            include ::QA::Page::Settings::Common

            view 'ee/app/views/groups/_custom_project_templates_setting.html.haml' do
              element :custom_project_template_select
              element :custom_project_templates
              element :save_changes_button
            end

            view 'ee/app/views/groups/settings/_ip_restriction.html.haml' do
              element :ip_restriction_field
            end

            def current_custom_project_template
              expand_section(:custom_project_templates)

              within_element(:custom_project_template_select) do
                current_selection
              end
            end

            def choose_custom_project_template(path)
              expand_section(:custom_project_templates)

              within_element(:custom_project_template_select) do
                clear_current_selection_if_present
              end
              click_element :custom_project_template_select
              search_and_select(path)
              click_element :save_changes_button
            end

            def set_ip_address_restriction(ip_address)
              expand_section(:permission_lfs_2fa_section)
              find_element(:ip_restriction_field).send_keys([:command, 'a'], :backspace)
              find_element(:ip_restriction_field).set ip_address
              click_element :save_permissions_changes_button
            end
          end
        end
      end
    end
  end
end
