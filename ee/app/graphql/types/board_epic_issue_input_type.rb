# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  class BoardEpicIssueInputBaseType < BaseInputObject
    argument :label_name, GraphQL::STRING_TYPE.to_list_type,
             required: false,
             description: 'Filter by label name'

    argument :milestone_title, GraphQL::STRING_TYPE,
             required: false,
             description: 'Filter by milestone title'

    argument :assignee_username, GraphQL::STRING_TYPE.to_list_type,
             required: false,
             description: 'Filter by assignee username'

    argument :author_username, GraphQL::STRING_TYPE,
             required: false,
             description: 'Filter by author username'

    argument :release_tag, GraphQL::STRING_TYPE,
             required: false,
             description: 'Filter by release tag'

    argument :epic_id, GraphQL::STRING_TYPE,
             required: false,
             description: 'Filter by epic ID'

    argument :my_reaction_emoji, GraphQL::STRING_TYPE,
             required: false,
             description: 'Filter by reaction emoji'

    argument :weight, GraphQL::STRING_TYPE,
             required: false,
             description: 'Filter by weight'
  end

  class NegatedBoardEpicIssueInputType < BoardEpicIssueInputBaseType
  end

  class BoardEpicIssueInputType < BoardEpicIssueInputBaseType
    graphql_name 'BoardEpicIssueInput'

    argument :not, Types::NegatedBoardEpicIssueInputType,
             required: false,
             description: 'List of negated params. Warning: this argument is experimental and a subject to change in future'
  end
  # rubocop: enable Graphql/AuthorizeTypes
end
