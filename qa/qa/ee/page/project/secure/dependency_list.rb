# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Secure
          class DependencyList < QA::Page::Base
            view 'ee/app/assets/javascripts/dependencies/components/app.vue' do
              element :dependency_list_all_count, "dependency_list_${label.toLowerCase().replace(' ', '_')" # rubocop:disable QA/ElementWithPattern
            end

            def has_dependency_count_of?(expected)
              find_element(:dependency_list_all_count).has_content?(expected)
            end
          end
        end
      end
    end
  end
end
