# frozen_string_literal: true

class ElasticMetricsUpdateWorker
  include ApplicationWorker
  include ExclusiveLeaseGuard
  # rubocop:disable Scalability/CronWorkerContext
  # This worker does not perform work scoped to a context
  include CronjobQueue
  # rubocop:enable Scalability/CronWorkerContext

  feature_category :global_search
  idempotent!

  LEASE_TIMEOUT = 5.minutes

  def perform
    try_obtain_lease { Elastic::MetricsUpdateService.new.execute }
  end

  private

  def lease_timeout
    LEASE_TIMEOUT
  end
end
