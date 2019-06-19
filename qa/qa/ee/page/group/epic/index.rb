# frozen_string_literal: true

module QA
  module EE
    module Page
      module Group
        module Epic
          class Index < QA::Page::Base
            view 'ee/app/assets/javascripts/epic/components/epic_create.vue' do
              element :new_epic_button
              element :epic_title
              element :create_epic_button
            end

            view 'ee/app/views/groups/epics/_epic.html.haml' do
              element :epic_title_text
            end

            def click_new_epic
              click_element :new_epic_button
            end

            def set_title(title)
              fill_element :epic_title, title
            end

            def create_new_epic
              click_element :create_epic_button
            end

            def click_first_epic(page = nil)
              all_elements(:epic_title_text).first.click
              page.validate_elements_present! if page
            end

            # This is a workaround to get the URL of the first epic
            # since this attribute is not exposed by the API.
            # See https://gitlab.com/gitlab-org/gitlab-ee/issues/11241.
            def web_url_of_first_epic
              page.all('.qa-epic-title-text a').first[:href]
            end
          end
        end
      end
    end
  end
end
