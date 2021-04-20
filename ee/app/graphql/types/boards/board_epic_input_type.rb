# frozen_string_literal: true

module Types
  module Boards
    class BoardEpicInputType < BoardIssuableInputBaseType
      graphql_name 'EpicFilters'

      class NegatedEpicBoardIssueInputType < BoardIssuableInputBaseType
      end

      argument :not, NegatedEpicBoardIssueInputType,
               required: false,
               description: <<~DESC
                 Negated epic arguments.
                 Warning: this argument is experimental and a subject to change in the future.
               DESC

      argument :search, GraphQL::STRING_TYPE,
               required: false,
               description: 'Search query for epic title or description.'
    end
  end
end
