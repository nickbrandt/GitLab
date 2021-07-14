# frozen_string_literal: true

module Types
  class NegatedMilestoneTimeboxEnum < BaseEnum
    graphql_name 'NegatedMilestoneTimebox'
    description 'Negated Milestone timebox values'

    value 'STARTED', 'An open, started milestone (start date <= today).'
    value 'UPCOMING', 'An open milestone due in the future (due date >= today).'
  end
end
