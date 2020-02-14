# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Settings
          module MergeRequest
            include Page::Component::SecureReport

            def self.prepended(page)
              page.module_eval do
                view 'ee/app/views/projects/_merge_pipelines_settings.html.haml' do
                  element :merged_results_pipeline_checkbox
                end
              end
            end

            def click_pipelines_for_merged_results_checkbox
              check_element :merged_results_pipeline_checkbox
            end
          end
        end
      end
    end
  end
end
