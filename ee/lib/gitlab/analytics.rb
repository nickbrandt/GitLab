# frozen_string_literal: true

module Gitlab
  module Analytics
    # Normally each analytics feature should be guarded with a feature flag.
    CODE_ANALYTICS_FEATURE_FLAG = :code_analytics
    CYCLE_ANALYTICS_FEATURE_FLAG = :cycle_analytics
    PRODUCTIVITY_ANALYTICS_FEATURE_FLAG = :productivity_analytics
    TASKS_BY_TYPE_CHART_FEATURE_FLAG = :tasks_by_type_chart

    FEATURE_FLAGS = [
      CODE_ANALYTICS_FEATURE_FLAG,
      CYCLE_ANALYTICS_FEATURE_FLAG,
      PRODUCTIVITY_ANALYTICS_FEATURE_FLAG,
      TASKS_BY_TYPE_CHART_FEATURE_FLAG
    ].freeze

    def self.any_features_enabled?
      FEATURE_FLAGS.any? { |flag| Feature.enabled?(flag) }
    end

    def self.code_analytics_enabled?
      Feature.enabled?(CODE_ANALYTICS_FEATURE_FLAG)
    end

    def self.cycle_analytics_enabled?
      Feature.enabled?(CYCLE_ANALYTICS_FEATURE_FLAG)
    end

    def self.productivity_analytics_enabled?
      Feature.enabled?(PRODUCTIVITY_ANALYTICS_FEATURE_FLAG)
    end
  end
end
