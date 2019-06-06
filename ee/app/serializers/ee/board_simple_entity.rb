# frozen_string_literal: true

module EE
  module BoardSimpleEntity
    extend ActiveSupport::Concern

    prepended do
      expose :name
      expose :milestone, using: EE::MilestoneSimple, if: ->(board, _) { board&.milestone_id }
    end
  end
end
