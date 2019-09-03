# frozen_string_literal: true

module QA
  module EE
    module Page
      module Group
        module Issue
          module Board
            class Show < QA::Page::Base
              view 'app/assets/javascripts/boards/components/boards_selector.vue' do
                element :boards_dropdown
                element :boards_dropdown_content
              end

              def boards_dropdown
                find_element(:boards_dropdown)
              end

              def boards_dropdown_content
                find_element(:boards_dropdown_content)
              end

              def click_boards_dropdown_button
                # The dropdown button comes from the `GlDropdown` component of `@gitlab/ui`,
                # so it wasn't possible to add a `data-qa-selector` to it.
                find_element(:boards_dropdown).find('button').click
              end
            end
          end
        end
      end
    end
  end
end
