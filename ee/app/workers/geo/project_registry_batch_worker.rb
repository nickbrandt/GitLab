# frozen_string_literal: true

module Geo
  # Responsible for scheduling multiple jobs to mark Project Registries as requiring syncing or verification.
  #
  # This class includes an Exclusive Lease guard and only one can be executed at the same time
  # If multiple jobs are scheduled, only one will run and the others will drop forever.
  class ProjectRegistryBatchWorker
    include ApplicationWorker
    include GeoQueue
    include ExclusiveLeaseGuard
    include ::Gitlab::Geo::LogHelpers

    BATCH_SIZE = 1000
    LEASE_TIMEOUT = 8.hours
    OPERATIONS = [:resync_repositories, :recheck_repositories].freeze

    def perform(operation)
      try_obtain_lease do
        case operation.to_sym
        when :resync_repositories
          resync_repositories
        when :recheck_repositories
          recheck_repositories
        else
          fail_invalid_operation!(operation)
        end
      end
    end

    private

    def resync_repositories
      Geo::ProjectRegistry.each_batch(of: BATCH_SIZE) do |batch|
        batch.flag_repositories_for_resync!
      end
    end

    def recheck_repositories
      Geo::ProjectRegistry.each_batch(of: BATCH_SIZE) do |batch|
        batch.flag_repositories_for_recheck!
      end
    end

    def lease_timeout
      LEASE_TIMEOUT
    end

    def fail_invalid_operation!(operation)
      raise ArgumentError, "Invalid operation: '#{operation.inspect}' informed. Must be one of the following: #{OPERATIONS.map { |valid_op| "'#{valid_op}'" }.join(', ')}"
    end
  end
end
