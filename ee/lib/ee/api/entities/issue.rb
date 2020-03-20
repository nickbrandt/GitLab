# frozen_string_literal: true

module EE
  module API
    module Entities
      module Issue
        extend ActiveSupport::Concern

        prepended do
          with_options if: -> (issue, options) { ::Ability.allowed?(options[:current_user], :read_epic, issue.project&.group) } do
            expose :epic_iid do |issue|
              issue.epic&.iid
            end

            expose :epic, using: EpicBaseEntity
          end
        end
      end
    end
  end
end
