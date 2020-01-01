# frozen_string_literal: true

class SelfMonitoringProjectCreateWorker
  include ApplicationWorker
  include ExclusiveLeaseGuard

  # This worker falls under Self-monitoring with Monitor::APM group. However,
  # self-monitoring is not classified as a feature category but rather as
  # Other Functionality. Metrics seems to be the closest feature_category for
  # this worker.
  feature_category :metrics

  LEASE_TIMEOUT = 15.minutes.to_i

  EXCLUSIVE_LEASE_KEY = 'self_monitoring_service_creation_deletion'

  CACHE_DATA_KEY = 'self_monitoring_create_result'

  def perform
    try_obtain_lease do
      result = Gitlab::DatabaseImporters::SelfMonitoring::Project::CreateService.new.execute
      Rails.cache.write(self.class.data_key(self.jid), result)
    end
  end

  # @param job_id [String] Job ID that is used to construct the cache keys.
  #   Returns the status of the given job ID.
  # @return [Hash] Returns a hash with a status key.
  #   The status key value can be :in_progress, :unknown or :completed. If the
  #   job has completed, an :output key will be returned with the output of the
  #   service that was executed by this worker.
  def self.status(job_id)
    running_or_enqueued = Gitlab::SidekiqStatus.job_status(Array.wrap(job_id)).first

    if running_or_enqueued
      return { status: :in_progress }
    end

    data = Rails.cache.read(self.data_key(job_id))

    if data.nil?
      return {
        status: :unknown,
        message: _('Status of job with ID "%{job_id}" could not be determined') %
          { job_id: job_id }
      }
    end

    { status: :completed, output: data }
  end

  def self.data_key(job_id)
    CACHE_DATA_KEY + ':' + job_id.to_s
  end

  private

  def lease_key
    EXCLUSIVE_LEASE_KEY
  end

  def lease_timeout
    LEASE_TIMEOUT
  end
end
