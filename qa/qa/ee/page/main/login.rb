# frozen_string_literal: true

module QA
  module EE
    module Page
      module Main
        module Login
          extend QA::Page::PageConcern

          def skip_onboarding
            Page::Main::Onboarding.perform(&:skip_if_visible)
          end
        end
      end
    end
  end
end
