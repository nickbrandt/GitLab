# frozen_string_literal: true

module EE
  module Banzai
    module Filter
      module IssueReferenceFilter
        extend ActiveSupport::Concern

        prepended do
          extend ::Gitlab::Utils::Override

          override :object_link_text_extras
          def object_link_text_extras(issue, matches)
            super + design_link_extras(issue, matches.named_captures['path'])
          end

          private

          def design_link_extras(issue, path)
            if path == '/designs' && read_designs?(issue)
              ['designs']
            else
              []
            end
          end

          def read_designs?(issue)
            Ability.allowed?(current_user, :read_design, issue)
          end
        end
      end
    end
  end
end
