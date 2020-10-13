# frozen_string_literal: true

module IncidentManagement
  class IncidentSlaExceededCheckWorker
    include ApplicationWorker
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

    idempotent!
    feature_category :incident_management

    def perform
      IssuableSla.exceeded_for_issues.find_in_batches do |incident_slas|
        incident_slas.each do |incident_sla|
          ApplyIncidentSlaExceededLabelWorker.perform_async(incident_sla.issue.id)

        rescue StandardError => e
          Gitlab::AppLogger.error("Error encountered in #{self.class.name}: #{e}")
        end
      end
    end
  end
end
