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
        IncidentManagement::AlertEscalation.ids.each do |escalation_id| # rubocop: disable CodeReuse/ActiveRecord
          IncidentManagement::Escalations::EscalationCheckWorker.perform_async('IncidentManagement::AlertEscalation', escalation_id)
        end
      end
    end
  end
end
