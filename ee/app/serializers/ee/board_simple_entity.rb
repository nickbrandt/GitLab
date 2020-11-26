# frozen_string_literal: true

module EE
  module BoardSimpleEntity
    extend ActiveSupport::Concern

    prepended do
      expose :milestone, using: EE::TimeboxSimple, if: ->(board, _) { board&.milestone_id }
      expose :iteration, using: EE::TimeboxSimple, if: ->(board, _) { board&.iteration_id }
    end
  end
end
