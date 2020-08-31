# frozen_string_literal: true

class ThrottledCleanupContainerRepositoryWorker < CleanupContainerRepositoryWorker
  urgency :throttled

  idempotent!
end
