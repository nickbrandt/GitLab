# frozen_string_literal: true

module Ci
  class BatchResetMinutesWorker
    include ApplicationWorker

    feature_category :continuous_integration
    idempotent!

    def perform(from_id, to_id)
      return unless Feature.enabled?(:ci_parallel_minutes_reset, default_enabled: true)

      Namespace.reset_ci_minutes_for_batch!(from_id, to_id)
    end
  end
end
