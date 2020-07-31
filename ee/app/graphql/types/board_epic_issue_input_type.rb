# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  class BoardEpicIssueInputType < BaseInputObject
    graphql_name 'BoardEpicIssueInput'

    argument :label_name, GraphQL::STRING_TYPE.to_list_type,
             required: false,
             description: 'Label applied to issues'

    argument :milestone_title, GraphQL::STRING_TYPE,
             required: false,
             description: 'Milestone applied to issues'

    argument :assignee_username, GraphQL::STRING_TYPE.to_list_type,
             required: false,
             description: 'Username of a user assigned to issues'

    argument :author_username, GraphQL::STRING_TYPE,
             required: false,
             description: 'Username of the issues author'

    argument :release_tag, GraphQL::STRING_TYPE,
             required: false,
             description: 'Release applied to issues'

    argument :epic_id, GraphQL::STRING_TYPE,
             required: false,
             description: 'Epic ID applied to issues'

    argument :my_reaction_emoji, GraphQL::STRING_TYPE,
             required: false,
             description: 'Reaction emoji applied to issues'

    argument :weight, GraphQL::STRING_TYPE,
             required: false,
             description: 'Weight applied to issues'
  end
  # rubocop: enable Graphql/AuthorizeTypes
end
