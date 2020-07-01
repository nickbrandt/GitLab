# frozen_string_literal: true

class ElasticClusterReindexingCronWorker
  include ApplicationWorker
  include CronjobQueue # rubocop:disable Scalability/CronWorkerContext
  include Gitlab::ExclusiveLeaseHelpers

  sidekiq_options retry: false

  feature_category :global_search
  urgency :throttled
  idempotent!

  def perform
    task = Elastic::ReindexingTask.current
    return false unless task

    in_lock(self.class.name.underscore, ttl: 1.hour, retries: 10, sleep_sec: 1) do
      service.execute
    end
  end

  private

  def service
    Elastic::ClusterReindexingService.new
  end
end
