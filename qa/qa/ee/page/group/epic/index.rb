# frozen_string_literal: true

module QA
  module EE
    module Page
      module Group
        module Epic
          class Index < QA::Page::Base
            view 'ee/app/assets/javascripts/epic/components/epic_create.vue' do
              element :new_epic_button
              element :epic_title_field
              element :create_epic_button
            end

            view 'ee/app/views/groups/epics/_epic.html.haml' do
              element :epic_title_text
            end

            def click_new_epic
              click_element :new_epic_button
            end

            def set_title(title)
              fill_element :epic_title_field, title
            end

            def create_new_epic
              click_element :create_epic_button
            end

            def click_first_epic(page = nil)
              all_elements(:epic_title_text).first.click
              page.validate_elements_present! if page
            end

            def has_epic_title?(title)
              wait do
                has_element?(:epic_title_text, text: title)
              end
            end
          end
        end
      end
    end
  end
end
