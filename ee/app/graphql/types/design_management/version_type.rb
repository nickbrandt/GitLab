# frozen_string_literal: true

module Types
  module DesignManagement
    class VersionType < BaseObject
      # Just `Version` might be a bit to general to expose globally so adding
      # a `Design` prefix to specify the class exposed in GraphQL
      graphql_name 'DesignVersion'

      authorize :read_design

      field :id, GraphQL::ID_TYPE, null: false,
            description: 'ID of the design version'
      field :sha, GraphQL::ID_TYPE, null: false,
            description: 'SHA of the design version'
      field :designs, Types::DesignManagement::DesignType.connection_type, null: false,
            description: 'All designs that were changed in the version'
    end
  end
end
