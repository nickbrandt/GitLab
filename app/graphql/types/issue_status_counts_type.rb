# frozen_string_literal: true

module Types
  class IssueStatusCountsType < BaseObject
    graphql_name 'IssueStatusCountsType'
    description "Represents total number of issues for the represented categories"

    authorize :read_issue

    ::Gitlab::IssuablesCountForState::STATES.each do |status|
      field status,
            GraphQL::INT_TYPE,
            null: true,
            description: "Number of issues with status #{status.upcase} for the project"
    end
  end
end
