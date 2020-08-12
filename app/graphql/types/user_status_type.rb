# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  class UserStatusType < BaseObject
    graphql_name 'UserStatus'

    field :message_html, GraphQL::STRING_TYPE, null: true,
      description: 'HTML of the user status message'
  end
end
