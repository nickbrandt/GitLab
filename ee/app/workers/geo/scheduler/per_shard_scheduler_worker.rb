# frozen_string_literal: true

module Geo
  module Scheduler
    class PerShardSchedulerWorker
      include ApplicationWorker
      include CronjobQueue # rubocop:disable Scalability/CronWorkerContext
      include ::Gitlab::Geo::LogHelpers
      include ::EachShardWorker

      feature_category :geo_replication

      def perform
        each_eligible_shard { |shard_name| schedule_job(shard_name) }
      end

      def schedule_job(shard_name)
        raise NotImplementedError
      end
    end
  end
end
