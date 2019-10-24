# frozen_string_literal: true

module Mutations
  module Epics
    class SetSubscription < Base
      graphql_name 'EpicSetSubscription'

      authorize :read_epic

      argument :group_path, GraphQL::ID_TYPE,
               required: true,
               description: 'The group the epic to (un)subscribe is in'

      argument :iid, GraphQL::ID_TYPE,
               required: true,
               description: 'The iid of the epic to (un)subscribe'

      argument :subscribed_state, GraphQL::BOOLEAN_TYPE,
               required: true,
               description: 'The desired state of the subscription'

      field :epic,
            Types::EpicType,
            null: true,
            description: 'The epic after mutation'

      def resolve(args)
        group_path = args.delete(:group_path)
        epic_iid = args.delete(:iid)
        desired_state = args.delete(:subscribed_state)

        epic = authorized_find!(group_path: group_path, iid: epic_iid)
        epic.set_subscription(current_user, desired_state)

        {
          epic: epic.reset,
          errors: errors_on_object(epic)
        }
      end
    end
  end
end
