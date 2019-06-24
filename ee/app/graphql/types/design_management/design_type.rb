# frozen_string_literal: true

module Types
  module DesignManagement
    class DesignType < BaseObject
      graphql_name 'Design'

      authorize :read_design

      implements(Types::Notes::NoteableType)

      field :id, GraphQL::ID_TYPE, null: false
      field :project, Types::ProjectType, null: false
      field :issue, Types::IssueType, null: false
      field :filename, GraphQL::STRING_TYPE, null: false
      field :image, GraphQL::STRING_TYPE, null: false, resolve: -> (design, _args, _ctx) do
        Gitlab::Routing.url_helpers.project_design_url(design.project, design)
      end
      field :versions,
            Types::DesignManagement::VersionType.connection_type,
            resolver: Resolvers::DesignManagement::VersionResolver,
            description: "All versions related to this design ordered newest first"
    end
  end
end
