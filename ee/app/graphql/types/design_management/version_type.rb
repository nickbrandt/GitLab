# frozen_string_literal: true

module Types
  module DesignManagement
    class VersionType < BaseObject
      # Just `Version` might be a bit to general to expose globally so adding
      # a `Design` prefix to specify the class exposed in GraphQL
      graphql_name 'DesignVersion'

      authorize :read_design

      field :id, GraphQL::ID_TYPE, null: false # rubocop:disable Graphql/Descriptions
      field :sha, GraphQL::ID_TYPE, null: false # rubocop:disable Graphql/Descriptions
      field :created_at, Types::TimeType, null: false, description: 'The time this version was created'
      field :designs,
            Types::DesignManagement::DesignType.connection_type,
            null: false,
            description: 'All designs that were changed in this version'
      field :author,
            Types::UserType,
            null: false,
            method: :lazy_author,
            description: 'The author of this version'
    end
  end
end
