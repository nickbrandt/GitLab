# frozen_string_literal: true

module Mutations
  module AlertManagement
    class ChangeAlertStatus < Base
      graphql_name 'ChangeAlertStatus'

      argument :status, Types::AlertManagement::StatusEnum,
               required: true,
               description: "The status to set the alert"

      def resolve(args)
        alert = find_alert(project_path: args[:project_path], iid: args[:iid])

        if alert
          service = ::AlertManagement::AlertService.new(alert)
          service.set_status!(args[:status])
        else
          self.errors = Array('Alert could not be found')
        end

        {
          alert: alert,
          errors: errors
        }
      end

      private

      attr_accessor :errors
    end
  end
end
