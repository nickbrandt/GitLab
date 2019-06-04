# frozen_string_literal: true

module Resolvers
  class IssueAssigneesResolver < BaseResolver
    argument  :iid,
              GraphQL::ID_TYPE,
              required: false,
              description: 'The IID of the label, e.g., "1"'
    argument  :iids,
              [GraphQL::ID_TYPE],
              required: false,
              description: 'The list of IIDs of labels, e.g., [1, 2]'
    argument  :name,
              GraphQL::STRING_TYPE,
              required: false,
              description: "The name of the user"
    argument  :username,
              GraphQL::STRING_TYPE,
              required: false,
              description: "The username of the user"
    argument  :avatar_url,
              GraphQL::STRING_TYPE,
              required: false,
              description: "Avatar image for user"
    argument  :web_url,
              GraphQL::STRING_TYPE,
              required: false,
              description: "The website of the user"

    type Types::UserType, null: true

    alias_method :issue, :object

    def resolve(**args)
      # The issue could have been loaded in batch by `BatchLoader`.
      # At this point we need the `id` of the issue to query for labels, so
      # make sure it's loaded and not `nil` before continuing.
      issue.sync if issue.respond_to?(:sync)
      return User.none if issue.nil?

      args[:ids] = issue.assignee_ids
      args[:iids] ||= [args[:iid]].compact

      UsersFinder.new(context[:current_user], args).execute
    end
  end
end
