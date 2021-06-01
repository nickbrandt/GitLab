# frozen_string_literal: true

module IncidentManagement
  module Escalations
    class ScheduleEscalationCheckCronWorker
      include ApplicationWorker
      # This worker does not perform work scoped to a context
      include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

      idempotent!
      feature_category :incident_management

      def perform
        IncidentManagement::AlertEscalation.all.each do |escalation|
          IncidentManagement::Escalations::EscalationCheckWorker.perform_async(escalation.class.name, escalation.id)
        end
      end
    end
  end
end
