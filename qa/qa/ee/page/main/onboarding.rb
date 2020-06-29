# frozen_string_literal: true

module QA
  module EE
    module Page
      module Main
        class Onboarding < QA::Page::Base
          view 'ee/app/assets/javascripts/onboarding/onboarding_welcome/components/welcome_page.vue' do
            element :skip_for_now_link, required: true
          end

          def skip_if_visible
            click_skip_for_now_link if visible?
          end

          def click_skip_for_now_link
            click_element :skip_for_now_link, ::QA::Page::Main::Menu
          end
        end
      end
    end
  end
end
