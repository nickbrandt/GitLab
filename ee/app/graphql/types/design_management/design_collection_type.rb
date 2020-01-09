# frozen_string_literal: true

module Types
  module DesignManagement
    class DesignCollectionType < BaseObject
      graphql_name 'DesignCollection'
      description 'A collection of designs.'

      authorize :read_design

      field :project, Types::ProjectType, null: false,
            description: 'Project associated with the design collection'
      field :issue, Types::IssueType, null: false,
            description: 'Issue associated with the design collection'
      field :designs, Types::DesignManagement::DesignType.connection_type, null: false,
            resolver: Resolvers::DesignManagement::DesignResolver,
            description: 'All designs for the design collection'
      # TODO: allow getting a single design by filename
      # exposing all designs
      field :versions, Types::DesignManagement::VersionType.connection_type,
            resolver: Resolvers::DesignManagement::VersionResolver,
            description: 'All versions related to all designs, ordered newest first'
    end
  end
end
