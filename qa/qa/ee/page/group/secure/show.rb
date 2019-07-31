# frozen_string_literal: true

module QA
  module EE
    module Page
      module Group::Secure
        class Show < QA::Page::Base
          view 'ee/app/assets/javascripts/security_dashboard/components/vulnerability_count.vue' do
            element :vulnerability_count, ':data-qa-selector="qaSelector"' # rubocop:disable QA/ElementWithPattern
          end

          view 'ee/app/assets/javascripts/security_dashboard/components/filter.vue' do
            element :filter_dropdown, ':data-qa-selector="qaSelector"' # rubocop:disable QA/ElementWithPattern
            element :filter_dropdown_content
          end

          def filter_project(project)
            find_element(:filter_project_dropdown).click
            within_element(:filter_dropdown_content) do
              click_on project
            end
          end

          def has_low_vulnerability_count_of?(expected)
            find_element(:vulnerability_count_low).has_content?(expected)
          end
        end
      end
    end
  end
end
