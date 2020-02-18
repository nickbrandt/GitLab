# frozen_string_literal: true

module Mutations
  module Epics
    class Update < Base
      prepend Mutations::SharedEpicArguments

      graphql_name 'UpdateEpic'

      argument :iid, GraphQL::STRING_TYPE,
               required: true,
               description: "The iid of the epic to mutate"

      argument :state_event,
                Types::EpicStateEventEnum,
                required: false,
                description: 'State event for the epic'

      argument :health_status,
               ::Types::HealthStatusEnum,
               required: false,
               description: 'The desired health status'

      field :epic,
            Types::EpicType,
            null: true,
            description: 'The epic after mutation'

      authorize :admin_epic

      def resolve(args)
        group_path = args.delete(:group_path)
        epic_iid = args.delete(:iid)

        validate_arguments!(args)

        epic = authorized_find!(group_path: group_path, iid: epic_iid)
        epic = ::Epics::UpdateService.new(epic.group, current_user, args).execute(epic)

        {
          epic: epic.reset,
          errors: errors_on_object(epic)
        }
      end
    end
  end
end
