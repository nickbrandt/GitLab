# frozen_string_literal: true

module Types
  class IterationStateEnum < BaseEnum
    graphql_name 'IterationState'
    description 'State of a GitLab iteration'

    value 'upcoming'
    value 'in_progress'
    value 'closed'
  end
end
