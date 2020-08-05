# frozen_string_literal: true

module Types
  class IssueStatusCountsType < BaseObject
    graphql_name 'IssueStatusCountsType'
    description "Represents total number of issues for the represented statuses"

    authorize :read_issue

    ::Gitlab::IssuablesCountForState::STATES.each do |state|
      next unless Issue.available_states.keys.push('all').include?(state)

      field state,
            GraphQL::INT_TYPE,
            null: true,
            description: "Number of issues with status #{state.upcase} for the project"
    end
  end
end
