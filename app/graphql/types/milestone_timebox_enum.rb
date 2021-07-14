# frozen_string_literal: true

module Types
  class MilestoneTimeboxEnum < BaseEnum
    graphql_name 'MilestoneTimebox'
    description 'Milestone timebox values'

    value 'NONE', 'No milestone is assigned.'
    value 'ANY', 'An milestone is assigned.'
    value 'STARTED', 'An open, started milestone (start date <= today).'
    value 'UPCOMING', 'An open milestone due in the future (due date >= today).'
  end
end
