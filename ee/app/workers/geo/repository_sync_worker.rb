# frozen_string_literal: true

module Geo
  class RepositorySyncWorker < Geo::Scheduler::Secondary::PerShardSchedulerWorker
    def schedule_job(shard_name)
      if ::Feature.enabled?(:geo_streaming_results_repository_sync)
        Geo::Secondary::RepositoryBackfillWorker.perform_async(shard_name)
      else
        Geo::RepositoryShardSyncWorker.perform_async(shard_name)
      end

      if Feature.enabled?(:enable_geo_design_sync)
        Geo::DesignRepositoryShardSyncWorker.perform_async(shard_name)
      end
    end
  end
end
