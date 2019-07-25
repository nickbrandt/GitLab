# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project::Secure
        class Show < QA::Page::Base
          view 'ee/app/assets/javascripts/security_dashboard/components/vulnerability_count.vue' do
            element :vulnerability_count, ':data-qa-selector="qaSelector"' # rubocop:disable QA/ElementWithPattern
          end

          def has_low_vulnerability_count_of?(expected)
            find_element(:vulnerability_count_low).has_content?(expected)
          end
        end
      end
    end
  end
end
