# frozen_string_literal: true

module Geo
  class RepositorySyncWorker < Geo::Scheduler::Secondary::PerShardSchedulerWorker
    def schedule_job(shard_name)
      # TODO: Put this behind a feature flag
      Geo::Secondary::RepositoryBackfillWorker.perform_async(shard_name)
    end
  end
end
