# frozen_string_literal: true

module Mutations
  module AlertManagement
    class UpdateAlertStatus < Base
      graphql_name 'UpdateAlertStatus'

      argument :status, Types::AlertManagement::StatusEnum,
               required: true,
               description: 'The status to set the alert'

      authorize :read_alert_management_alerts

      def resolve(args)
        alert = authorized_find!(project_path: args[:project_path], iid: args[:iid])

        if alert
          result = update_status(alert, args[:status])
          prepare_response(result)
        else
          {
            alert: alert,
            errors: ['Alert could not be found']
          }
        end
      end

      private

      def update_status(alert, status)
        service = ::AlertManagement::UpdateAlertStatusService.new(alert, status)
        service.execute!
      end

      def prepare_response(result)
        {
          alert: result.payload[:alert],
          errors: result.message.present? ? [result.message] : []
        }
      end
    end
  end
end
