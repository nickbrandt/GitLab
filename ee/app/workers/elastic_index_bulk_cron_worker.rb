# frozen_string_literal: true

class ElasticIndexBulkCronWorker
  include ApplicationWorker
  include Gitlab::ExclusiveLeaseHelpers

  # There is no onward scheduling and this cron handles work from across the
  # application, so there's no useful context to add.
  include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

  feature_category :global_search
  idempotent!
  urgency :throttled

  def perform
    if Elastic::IndexingControl.non_cached_pause_indexing?
      logger.info(message: 'elasticsearch_pause_indexing setting is enabled. ElasticBulkCronWorker execution is skipped.')
      return false
    end

    in_lock(self.class.name.underscore, ttl: 10.minutes, retries: 10, sleep_sec: 1) do
      records_count = Elastic::ProcessBookkeepingService.new.execute
      log_extra_metadata_on_done(:records_count, records_count)
    end
  rescue Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError
    # We're scheduled on a cronjob, so nothing to do here
  end

  private

  def logger
    Elastic::IndexingControl.logger
  end
end
