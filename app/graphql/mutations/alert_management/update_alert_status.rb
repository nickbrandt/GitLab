# frozen_string_literal: true

module Mutations
  module AlertManagement
    class UpdateAlertStatus < Base
      graphql_name 'UpdateAlertStatus'

      argument :status, Types::AlertManagement::StatusEnum,
               required: true,
               description: 'The status to set the alert'

      argument :ended_at, Types::TimeType,
               required: false,
               description: 'Ended time of resolved alert. Current time when omitted.'

      def resolve(args)
        alert = authorized_find!(project_path: args[:project_path], iid: args[:iid])
        result = update_status(alert, args.slice(:status, :ended_at))

        prepare_response(result)
      end

      private

      def update_status(alert, params)
        ::AlertManagement::UpdateAlertStatusService
          .new(alert, current_user, params)
          .execute
      end

      def prepare_response(result)
        {
          alert: result.payload[:alert],
          errors: result.error? ? [result.message] : []
        }
      end
    end
  end
end
