# frozen_string_literal: true

module QA
  module EE
    module Page
      module Main
        module Onboarding
          extend QA::Page::PageConcern

          def self.prepended(base)
            super

            base.class_eval do
              view 'ee/app/assets/javascripts/onboarding/onboarding_welcome/components/welcome_page.vue' do
                element :skip_for_now_link, required: true
              end
            end
          end

          def skip_for_now
            click_element :skip_for_now_link, ::QA::Page::Main::Menu
          end
        end
      end
    end
  end
end
