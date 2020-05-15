# frozen_string_literal: true

module Mutations
  module Iterations
    class Create < BaseMutation
      include Mutations::ResolvesGroup

      graphql_name 'CreateIteration'

      authorize :create_iteration

      field :iteration,
            Types::IterationType,
            null: true,
            description: 'The created iteration'

      argument :group_path, GraphQL::ID_TYPE,
               required: true,
               description: "The target group for the iteration"

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

        validate_arguments!(args)

        group = authorized_find!(group_path: group_path)
        response = ::Iterations::CreateService.new(group, current_user, args).execute

        response_object = response.payload[:iteration] if response.success?
        response_errors = response.error? ? response.payload[:errors].full_messages : []

        {
            iteration: response_object,
            errors: response_errors
        }
      end

      private

      def find_object(group_path:)
        resolve_group(full_path: group_path)
      end

      def validate_arguments!(args)
        if args.empty?
          raise Gitlab::Graphql::Errors::ArgumentError,
                'The list of iteration attributes is empty'
        end
      end
    end
  end
end
