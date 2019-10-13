# frozen_string_literal: true

module Types
  module DesignManagement
    class DesignType < BaseObject
      graphql_name 'Design'

      authorize :read_design

      implements(Types::Notes::NoteableType)

      alias_method :design, :object

      field :id, GraphQL::ID_TYPE, null: false # rubocop:disable Graphql/Descriptions
      field :project, Types::ProjectType, null: false # rubocop:disable Graphql/Descriptions
      field :issue, Types::IssueType, null: false # rubocop:disable Graphql/Descriptions
      field :notes_count,
            GraphQL::INT_TYPE,
            null: false,
            method: :user_notes_count,
            description: 'The total count of user-created notes for this design'
      field :filename, GraphQL::STRING_TYPE, null: false # rubocop:disable Graphql/Descriptions
      field :full_path, GraphQL::STRING_TYPE, null: false # rubocop:disable Graphql/Descriptions
      field :event,
            Types::DesignManagement::DesignVersionEventEnum,
            null: false,
            description: 'The change that happened to the design at this version',
            extras: [:parent]
      field :image, GraphQL::STRING_TYPE, null: false, extras: [:parent] # rubocop:disable Graphql/Descriptions
      field :diff_refs, Types::DiffRefsType, null: false, calls_gitaly: true # rubocop:disable Graphql/Descriptions
      field :versions,
            Types::DesignManagement::VersionType.connection_type,
            resolver: Resolvers::DesignManagement::VersionResolver,
            description: 'All versions related to this design ordered newest first',
            extras: [:parent]

      def image(parent:)
        sha = cached_stateful_version(parent).sha

        Gitlab::Routing.url_helpers.project_design_url(design.project, design, sha)
      end

      def event(parent:)
        version = cached_stateful_version(parent)

        action = cached_actions_for_version(version)[design.id]

        action&.event || Types::DesignManagement::DesignVersionEventEnum::NONE
      end

      # Returns a `DesignManagement::Version` for this query based on the
      # `atVersion` argument passed to a parent node if present, or otherwise
      # the most recent `Version` for the issue.
      def cached_stateful_version(parent_node)
        version_gid = Gitlab::Graphql::FindArgumentInParent.find(parent_node, :at_version)

        # Caching is scoped to an `issue_id` to allow us to cache the
        # most recent `Version` for an issue
        Gitlab::SafeRequestStore.fetch([request_cache_base_key, 'stateful_version', object.issue_id, version_gid]) do
          if version_gid
            GitlabSchema.object_from_id(version_gid)&.sync
          else
            object.issue.design_versions.most_recent
          end
        end
      end

      def cached_actions_for_version(version)
        Gitlab::SafeRequestStore.fetch([request_cache_base_key, 'actions_for_version', version.id]) do
          version.actions.to_h { |dv| [dv.design_id, dv] }
        end
      end

      def request_cache_base_key
        self.class.name
      end
    end
  end
end
