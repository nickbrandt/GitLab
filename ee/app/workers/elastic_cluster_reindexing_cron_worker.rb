# frozen_string_literal: true

class ElasticClusterReindexingCronWorker
  include ApplicationWorker
  include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

  feature_category :global_search
  urgency :throttled
  idempotent!

  def perform
    task = ReindexingTask.current
    return false unless task

    service.execute
  end

  private

  def service
    Elastic::ClusterReindexingService.new
  end
end
