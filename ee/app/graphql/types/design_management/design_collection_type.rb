# frozen_string_literal: true

module Types
  module DesignManagement
    class DesignCollectionType < BaseObject
      graphql_name 'DesignCollection'

      authorize :read_design

      field :project, Types::ProjectType, null: false
      field :issue, Types::IssueType, null: false
      field :designs,
            Types::DesignManagement::DesignType.connection_type,
            null: false,
            resolver: Resolvers::DesignManagement::DesignResolver,
            description: "All visible designs for this collection"
      # TODO: allow getting a single design by filename
      # TODO: when we allow hiding designs, we will also expose a relation
      # exposing all designs
      field :versions,
            Types::DesignManagement::VersionType.connection_type,
            resolver: Resolvers::DesignManagement::VersionResolver,
            description: "All versions related to all designs ordered newest first"
    end
  end
end
