# frozen_string_literal: true

module Mutations
  module Iterations
    class Update < Base
      include Mutations::ResolvesGroup

      graphql_name 'UpdateIteration'

      authorize :admin_iteration

      field :iteration,
            Types::IterationType,
            null: true,
            description: 'The iteration after mutation'

      argument :iid, GraphQL::ID_TYPE,
               required: true,
               description: "The iid of the iteration to mutate"

      argument :group_path, GraphQL::ID_TYPE,
               required: true,
               description: 'The group the iteration to mutate belongs to'

      argument :state_event,
               Types::IterationStateEventEnum,
               required: false,
               description: 'State event for the iteration'

      argument :title,
               GraphQL::STRING_TYPE,
               required: false,
               description: 'The title of the iteration'

      argument :description,
               GraphQL::STRING_TYPE,
               required: false,
               description: 'The description of the iteration'

      argument :start_date,
               GraphQL::STRING_TYPE,
               required: false,
               description: 'The start date of the iteration'

      argument :due_date,
               GraphQL::STRING_TYPE,
               required: false,
               description: 'The end date of the iteration'

      def resolve(args)
        group_path = args.delete(:group_path)
        iteration_iid = args.delete(:iid)

        validate_arguments!(args)

        iteration = authorized_find!(group_path: group_path, iid: iteration_iid)
        iteration = ::Iterations::UpdateService.new(iteration.group, current_user, args).execute(iteration)

        {
            iteration: iteration.reset,
            errors: errors_on_object(iteration)
        }
      end

      private

      def find_object(group_path:, iid:)
        group = resolve_group(full_path: group_path)

        resolver = Resolvers::IterationsResolver
                       .single.new(object: group, context: context, field: nil)

        resolver.resolve(iid: iid)
      end
    end
  end
end
