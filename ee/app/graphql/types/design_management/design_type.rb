# frozen_string_literal: true

module Types
  module DesignManagement
    class DesignType < BaseObject
      graphql_name 'Design'

      authorize :read_design

      field :id, GraphQL::ID_TYPE, null: false
      field :project, Types::ProjectType, null: false
      field :issue, Types::IssueType, null: false
      field :filename, GraphQL::STRING_TYPE, null: false
      field :versions,
            Types::DesignManagement::VersionType.connection_type,
            resolver: Resolvers::DesignManagement::VersionResolver,
            description: "All versions related to this design ordered newest first"
    end
  end
end
