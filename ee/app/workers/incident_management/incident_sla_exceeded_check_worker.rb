# frozen_string_literal: true

module IncidentManagement
  class IncidentSlaExceededCheckWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext


    idempotent!
    feature_category :incident_management

    def perform
      IncidentSla.exceeded.find_in_batches do |incident_slas|
        incident_slas.each do |incident_sla|
          ApplyIncidentSlaExceededLabelService.new(incident_sla.issue).execute

          rescue StandardError => e
          Gitlab::AppLogger.error("Error encountered in #{self.class.name}: #{e}")
        end
      end
    end
  end
end
