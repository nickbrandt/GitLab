# frozen_string_literal: true

module Types
  module DesignManagement
    class DesignType < BaseObject
      graphql_name 'Design'

      authorize :read_design

      implements(Types::Notes::NoteableType)

      alias_method :design, :object

      field :id, GraphQL::ID_TYPE, null: false
      field :project, Types::ProjectType, null: false
      field :issue, Types::IssueType, null: false
      field :notes_count,
            GraphQL::INT_TYPE,
            null: false,
            method: :user_notes_count,
            description: 'The total count of user-created notes for this design'
      field :filename, GraphQL::STRING_TYPE, null: false
      field :full_path, GraphQL::STRING_TYPE, null: false
      field :image, GraphQL::STRING_TYPE, null: false, extras: [:parent]
      field :diff_refs, Types::DiffRefsType, null: false, calls_gitaly: true
      field :versions,
            Types::DesignManagement::VersionType.connection_type,
            resolver: Resolvers::DesignManagement::VersionResolver,
            description: "All versions related to this design ordered newest first",
            extras: [:parent]

      def image(parent:)
        # Find an `at_version` argument passed to a parent node.
        #
        # If no argument is found then a nil value for sha is fine
        # and the image displayed will be the latest version
        version_id = Gitlab::Graphql::FindArgumentInParent.find(parent, :at_version, limit_depth: 4)
        sha = version_id ? GitlabSchema.object_from_id(version_id).sha : nil

        project = Gitlab::Graphql::Loaders::BatchModelLoader.new(Project, design.project_id).find

        Gitlab::Routing.url_helpers.project_design_url(project, design, sha)
      end
    end
  end
end
