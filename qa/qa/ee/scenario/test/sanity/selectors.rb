# frozen_string_literal: true

module QA
  module EE
    module Scenario
      module Test
        module Sanity
          module Selectors
            def pages
              @ee_pages ||= super + [QA::EE::Page]
            end
          end
        end
      end
    end
  end
end
