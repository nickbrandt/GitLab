# frozen_string_literal: true

module Gitlab
  module Analytics
    # Normally each analytics feature should be guarded with a feature flag.
    CYCLE_ANALYTICS_FEATURE_FLAG = :cycle_analytics
    PRODUCTIVITY_ANALYTICS_FEATURE_FLAG = :productivity_analytics

    FEATURE_FLAGS = [
      CYCLE_ANALYTICS_FEATURE_FLAG,
      PRODUCTIVITY_ANALYTICS_FEATURE_FLAG
    ].freeze

    def self.any_features_enabled?
      FEATURE_FLAGS.any? { |flag| Feature.enabled?(flag) }
    end

    def self.cycle_analytics_enabled?
      Feature.enabled?(CYCLE_ANALYTICS_FEATURE_FLAG)
    end

    def self.productivity_analytics_enabled?
      Feature.enabled?(PRODUCTIVITY_ANALYTICS_FEATURE_FLAG)
    end
  end
end
