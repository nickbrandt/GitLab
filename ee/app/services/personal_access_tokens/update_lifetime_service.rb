# frozen_string_literal: true

module PersonalAccessTokens
  class UpdateLifetimeService
    include ExclusiveLeaseGuard

    DEFAULT_LEASE_TIMEOUT = 3.hours.to_i

    def execute
      try_obtain_lease do
        ::PersonalAccessTokens::PolicyWorker.perform_in(DEFAULT_LEASE_TIMEOUT)
      end
    end

    private

    # Used by ExclusiveLeaseGuard
    def lease_timeout
      DEFAULT_LEASE_TIMEOUT
    end

    # Used by ExclusiveLeaseGuard
    # Overriding value as we never release the lease
    # before the timeout in order to prevent multiple
    # PersonalAccessTokens::PolicyWorker to start in
    # a short span of time
    def lease_release?
      false
    end
  end
end
