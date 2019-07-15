# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Settings
          class MergeRequestApproval < QA::Page::Base
            view 'ee/app/views/projects/_merge_request_approvals_settings_form.html.haml' do
              element :require_code_owners_approval_checkbox
            end

            view 'ee/app/views/projects/_merge_request_approvals_settings.html.haml' do
              element :save_merge_request_approval_settings_button
            end

            def click_require_code_owners_approval_checkbox
              check_element :require_code_owners_approval_checkbox
            end

            def click_save_merge_request_approval_button
              click_element :save_merge_request_approval_settings_button
            end
          end
        end
      end
    end
  end
end
