# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Settings
          module Main
            def self.prepended(page)
              page.module_eval do
                view 'ee/app/views/projects/_merge_request_approvals_settings.html.haml' do
                  element :merge_request_approval_settings
                end
              end
            end

            def expand_request_approval_settings(&block)
              expand_section(:merge_request_approval_settings) do
                MergeRequestApproval.perform(&block)
              end
            end
          end
        end
      end
    end
  end
end
