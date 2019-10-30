# frozen_string_literal: true

module Mutations
  module Epics
    class Update < BaseMutation
      include Mutations::ResolvesGroup

      graphql_name 'UpdateEpic'

      argument :group_path, GraphQL::ID_TYPE,
               required: true,
               description: "The group the epic to mutate is in"

      argument :iid, GraphQL::STRING_TYPE,
               required: true,
               description: "The iid of the epic to mutate"

      argument :title,
                GraphQL::STRING_TYPE,
                required: false,
                description: 'The title of the epic'

      argument :description,
                GraphQL::STRING_TYPE,
                required: false,
                description: 'The description of the epic'

      argument :start_date_fixed,
                GraphQL::STRING_TYPE,
                required: false,
                description: 'The start date of the epic'

      argument :due_date_fixed,
                GraphQL::STRING_TYPE,
                required: false,
                description: 'The end date of the epic'

      argument :start_date_is_fixed,
                GraphQL::BOOLEAN_TYPE,
                required: false,
                description: 'Indicates start date should be sourced from start_date_fixed field not the issue milestones'

      argument :due_date_is_fixed,
                GraphQL::BOOLEAN_TYPE,
                required: false,
                description: 'Indicates end date should be sourced from due_date_fixed field not the issue milestones'

      argument :state_event,
                Types::EpicStateEventEnum,
                required: false,
                description: 'State event for the epic'

      field :epic,
            Types::EpicType,
            null: true,
            description: 'The epic after mutation'

      authorize :admin_epic

      def resolve(args)
        group_path = args.delete(:group_path)
        epic_iid = args.delete(:iid)

        if args.empty?
          raise Gitlab::Graphql::Errors::ArgumentError,
            "The list of attributes to update is empty"
        end

        epic = authorized_find!(group_path: group_path, iid: epic_iid)
        epic = ::Epics::UpdateService.new(epic.group, current_user, args).execute(epic)

        {
          epic: epic.reset,
          errors: errors_on_object(epic)
        }
      end

      private

      def find_object(group_path:, iid:)
        group = resolve_group(full_path: group_path)
        resolver = Resolvers::EpicResolver
          .single.new(object: group, context: context)

        resolver.resolve(iid: iid)
      end
    end
  end
end
