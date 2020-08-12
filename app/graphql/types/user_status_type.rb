# frozen_string_literal: true

module Types
  class UserStatusType < BaseObject
    graphql_name 'UserStatus'
    expose_permissions Types::PermissionTypes::User

    field :message_html, GraphQL::STRING_TYPE, null: true,
      description: 'HTML of the user status message'
  end
end
