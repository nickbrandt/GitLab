# frozen_string_literal: true

module Mutations
  module Requirements
    class Update < BaseMutation
      include Mutations::ResolvesProject

      graphql_name 'UpdateRequirement'

      authorize :update_requirement

      field :requirement, Types::RequirementType,
            null: true,
            description: 'The requirement after mutation'

      argument :title, GraphQL::STRING_TYPE,
               required: false,
               description: 'Title of the requirement'

      argument :state, Types::RequirementStateEnum,
               required: false,
               description: 'State of the requirement'

      argument :iid, GraphQL::STRING_TYPE,
               required: true,
               description: 'The iid of the requirement to update'

      argument :project_path, GraphQL::ID_TYPE,
               required: true,
               description: 'The project full path the requirement is associated with'

      def ready?(**args)
        if args.values_at(:title, :state).compact.blank?
          raise Gitlab::Graphql::Errors::ArgumentError,
            'title or state argument is required'
        end

        super
      end

      def resolve(args)
        project_path = args.delete(:project_path)
        requirement_iid = args.delete(:iid)
        requirement = authorized_find!(project_path: project_path, iid: requirement_iid)

        requirement = ::RequirementsManagement::UpdateRequirementService.new(
          requirement.project,
          context[:current_user],
          args
        ).execute(requirement)

        {
          requirement: requirement.reset,
          errors: errors_on_object(requirement)
        }
      end

      private

      def find_object(project_path:, iid:)
        project = resolve_project(full_path: project_path)

        resolver = Resolvers::RequirementsResolver
          .single.new(object: project, context: context, field: nil)

        resolver.resolve(iid: iid)
      end
    end
  end
end
