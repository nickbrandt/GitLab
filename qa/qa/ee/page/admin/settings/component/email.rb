# frozen_string_literal: true

module QA
  module EE
    module Page
      module Admin
        module Settings
          module Component
            class Email < QA::Page::Base
              view 'app/views/admin/application_settings/_email.html.haml' do
                element :save_changes_button
              end

              view 'ee/app/views/admin/application_settings/_email_additional_text_setting.html.haml' do
                element :additional_text_textarea_field
              end

              def additional_text_textarea_text
                find_element(:additional_text_textarea_field).text
              end

              def fill_additional_text(text)
                fill_element(:additional_text_textarea_field, text)
              end

              def save_changes
                click_element(:save_changes_button)
              end
            end
          end
        end
      end
    end
  end
end
