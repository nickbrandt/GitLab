# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project::Secure
        class DependencyList < QA::Page::Base
          view 'ee/app/assets/javascripts/dependencies/components/app.vue' do
            element :dependency_list_total_content
          end

          def has_dependency_count_of?(expected)
            find_element(:dependency_list_total_content).has_content?(expected)
          end
        end
      end
    end
  end
end
