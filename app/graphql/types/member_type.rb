# frozen_string_literal: true
# rubocop:disable Graphql/AuthorizeTypes
module Types
  class MemberType < BaseObject
    graphql_name 'Member'

    field :access_level, Types::AccessLevelType, null: true,
          description: 'GitLab::Access level'

    field :source_type, GraphQL::STRING_TYPE, null: true,
          description: 'Polymorphic source type (e.g. Project or Group)'

    field :created_by, Types::UserType, null: true,
          description: 'User that authorized membership'

    field :created_at, Types::TimeType, null: true,
          description: 'Date and time the membership was created'

    field :updated_at, Types::TimeType, null: true,
          description: 'Date and time the membership was last updated'

    field :expires_at, Types::TimeType, null: true,
          description: 'Date and time the membership expires'

    field :source, Types::SourceType, null: true,
          description: 'Source object'
  end
end
