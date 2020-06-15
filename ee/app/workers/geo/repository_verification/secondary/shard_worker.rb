# frozen_string_literal: true

module Geo
  module RepositoryVerification
    module Secondary
      class ShardWorker < Geo::Scheduler::Secondary::SchedulerWorker # rubocop:disable Scalability/IdempotentWorker
        # rubocop:disable Scalability/CronWorkerContext
        # This worker does not perform work scoped to a context
        include CronjobQueue
        # rubocop:enable Scalability/CronWorkerContext
        attr_accessor :shard_name

        loggable_arguments 0

        def perform(shard_name)
          @shard_name = shard_name

          return unless Gitlab::ShardHealthCache.healthy_shard?(shard_name)

          super()
        end

        def lease_key
          @lease_key ||= "#{self.class.name.underscore}:shard:#{shard_name}"
        end

        private

        def skip_cache_key
          "#{self.class.name.underscore}:shard:#{shard_name}:skip"
        end

        def worker_metadata
          { shard: shard_name }
        end

        def max_capacity
          current_node.verification_max_capacity
        end

        def load_pending_resources
          Geo::ProjectRegistryPendingVerificationFinder
            .new(current_node: current_node, shard_name: shard_name, batch_size: db_retrieve_batch_size)
            .execute
            .pluck_primary_key
        end

        def schedule_job(registry_id)
          job_id = Geo::RepositoryVerification::Secondary::SingleWorker.perform_async(registry_id)

          { id: registry_id, job_id: job_id } if job_id
        end
      end
    end
  end
end
