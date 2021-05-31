# frozen_string_literal: true

module Types
  module RequirementsManagement
    class RequirementStateEnum < BaseEnum
      graphql_name 'RequirementState'
      description 'State of a requirement'

      value 'OPENED', value: 'opened'
      value 'CLOSED', value: 'closed'
      # remove this alias in %14.6
      value 'ARCHIVED', value: 'closed'
    end
  end
end
