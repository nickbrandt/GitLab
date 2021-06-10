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
        IncidentManagement::AlertEscalation.select(:id).find_in_batches do |escalation_ids|
          args = escalation_ids.map { |escalation| [escalation.id] }
          IncidentManagement::Escalations::AlertEscalationCheckWorker.bulk_perform_async(args) # rubocop:disable Scalability/BulkPerformWithContext
        end
      end
    end
  end
end
