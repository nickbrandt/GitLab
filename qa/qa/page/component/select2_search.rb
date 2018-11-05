# frozen_string_literal: true

module QA
  module Page
    module Component
      module Select2Search
        def search_and_select(item)
          wait(reload: false) do
            page.has_css?('.select2-input')
          end

          find('.select2-input').set(item)
          find('.select2-result-label', text: item).click
        end
      end
    end
  end
end
