# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Settings
          module Repository
            def self.prepended(page)
              page.module_eval do
                view 'ee/app/views/projects/push_rules/_index.html.haml' do
                  element :push_rules_content
                end
              end
            end

            def expand_push_rules(&block)
              expand_section(:push_rules_content) do
                PushRules.perform(&block)
              end
            end
          end
        end
      end
    end
  end
end
