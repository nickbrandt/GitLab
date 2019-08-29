# frozen_string_literal: true

module QA
  module EE
    module Page
      module Admin
        module Settings
          class Preferences < QA::Page::Base
            include QA::Page::Settings::Common

            view 'app/views/admin/application_settings/preferences.html.haml' do
              element :email_section
            end

            def expand_email_settings(&block)
              expand_section(:email_section) do
                Component::Email.perform(&block)
              end
            end
          end
        end
      end
    end
  end
end
