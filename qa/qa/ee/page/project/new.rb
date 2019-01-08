# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module New
          def self.prepended(page)
            page.module_eval do
              view 'ee/app/views/projects/_project_templates.html.haml' do
                element :group_templates_tab
                element :group_template_tab_badge
              end

              view 'ee/app/views/users/_custom_project_templates_from_groups.html.haml' do
                element :use_template_button
                element :template_option_row
              end
            end
          end

          def go_to_create_from_template_group_tab
            go_to_create_from_template
            click_element(:group_templates_tab)
          end

          def group_template_tab_badge_text
            find_element(:group_template_tab_badge).text
          end

          def use_template_for_project(project_name)
            within find_element(:template_option_row, project_name) do
              click_element :use_template_button
            end
          end
        end
      end
    end
  end
end
