# frozen_string_literal: true

module Types
  class EpicIssueType < IssueType
    graphql_name 'EpicIssue'

    present_using EpicIssuePresenter

    field :epic_issue_id, GraphQL::ID_TYPE, null: false

    field :relation_path, GraphQL::STRING_TYPE, null: true, resolve: -> (issue, args, ctx) do
      issue.group_epic_issue_path(ctx[:current_user])
    end
  end
end
