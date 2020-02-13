# frozen_string_literal: true

module Geo
  module Secondary
    # Iterates over syncable records and creates the corresponding registry
    # records which are missing. Then, the workers that actually schedule the
    # sync work only have to query the registry table for never-synced records.
    class RegistryConsistencyWorker
      include ApplicationWorker
      prepend Reenqueuer
      include ::Gitlab::Geo::LogHelpers

      # There is no relevant user/project/namespace/caller context for this worker
      include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

      feature_category :geo_replication

      # This is probably not the best place to "register" replicables for this functionality
      REGISTRY_CLASSES = [Geo::LfsObjectRegistry].freeze
      BATCH_SIZE = 1000

      # @return [Boolean] true if at least 1 registry was created, else false
      def perform
        return false unless registry_classes.any? # May as well remove this check after one registry no longer feature flags this
        return false unless Gitlab::Geo.secondary?

        backfill
      rescue => e
        log_error("Error while backfilling all", e)

        raise
      end

      def lease_timeout
        [registry_classes.size, 1].max * 1.minute
      end

      private

      def backfill
        log_info("Backfill registries", registry_classes: registry_classes.map(&:to_s), batch_size: BATCH_SIZE)

        registry_classes.any? do |registry_class|
          Geo::RegistryConsistencyService.new(registry_class, batch_size: BATCH_SIZE).execute
        end
      end

      def registry_classes
        @registry_classes = REGISTRY_CLASSES.select(&:registry_consistency_worker_enabled?)
      end
    end
  end
end
