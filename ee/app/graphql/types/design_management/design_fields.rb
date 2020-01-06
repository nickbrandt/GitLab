# frozen_string_literal: true

module Types
  module DesignManagement
    module DesignFields
      include BaseInterface

      field_class Types::BaseField

      field :id, GraphQL::ID_TYPE, description: 'The ID of this design', null: false
      field :project, Types::ProjectType, null: false, description: 'The project the design belongs to'
      field :issue, Types::IssueType, null: false, description: 'The issue the design belongs to'
      field :filename, GraphQL::STRING_TYPE, null: false, description: 'The filename of the design'
      field :full_path, GraphQL::STRING_TYPE, null: false, description: 'The full path to the design file'
      field :image, GraphQL::STRING_TYPE, null: false, extras: [:parent], description: 'The URL of the image'
      field :diff_refs, Types::DiffRefsType,
            null: false,
            calls_gitaly: true,
            extras: [:parent],
            description: 'The diff refs for this design'
      field :event, Types::DesignManagement::DesignVersionEventEnum,
            null: false,
            extras: [:parent],
            description: 'How this design was changed in the current version'
      field :notes_count,
            GraphQL::INT_TYPE,
            null: false,
            method: :user_notes_count,
            description: 'The total count of user-created notes for this design'

      def diff_refs(parent:)
        version = cached_stateful_version(parent)
        version.diff_refs
      end

      def image(parent:)
        sha = cached_stateful_version(parent).sha

        GitlabSchema.after_lazy(project) do |proj|
          ::Gitlab::Routing.url_helpers.project_design_url(proj, design, sha)
        end
      end

      def event(parent:)
        version = cached_stateful_version(parent)

        action = cached_actions_for_version(version)[design.id]

        action&.event || ::Types::DesignManagement::DesignVersionEventEnum::NONE
      end

      def cached_actions_for_version(version)
        Gitlab::SafeRequestStore.fetch(['DesignFields', 'actions_for_version', version.id]) do
          version.actions.to_h { |dv| [dv.design_id, dv] }
        end
      end

      def project
        ::Gitlab::Graphql::Loaders::BatchModelLoader.new(::Project, design.project_id, :inc_routes).find
      end

      def issue
        ::Gitlab::Graphql::Loaders::BatchModelLoader.new(::Issue, design.issue_id).find
      end
    end
  end
end
