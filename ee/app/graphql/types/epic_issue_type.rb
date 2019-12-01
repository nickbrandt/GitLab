# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  # This is a subclass of `IssueType` which has authorization
  class EpicIssueType < IssueType
    graphql_name 'EpicIssue'

    present_using EpicIssuePresenter

    field :epic_issue_id, GraphQL::ID_TYPE, null: false # rubocop:disable Graphql/Descriptions

    field :relation_path, GraphQL::STRING_TYPE, null: true, resolve: -> (issue, args, ctx) do # rubocop:disable Graphql/Descriptions
      issue.group_epic_issue_path(ctx[:current_user])
    end

    field :id, GraphQL::ID_TYPE, null: true, resolve: -> (issue, args, ctx) do
      issue.to_global_id
    end, description: 'The global id of the epic-issue relation'

    def epic_issue_id
      "gid://gitlab/EpicIssue/#{object.epic_issue_id}"
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
