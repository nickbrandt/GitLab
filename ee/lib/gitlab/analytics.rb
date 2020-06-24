# frozen_string_literal: true

module Gitlab
  module Analytics
    # Normally each analytics feature should be guarded with a feature flag.
    CYCLE_ANALYTICS_FEATURE_FLAG = :cycle_analytics
    PRODUCTIVITY_ANALYTICS_FEATURE_FLAG = :productivity_analytics
    REPORT_PAGES_FEATURE_FLAG = :report_pages

    FEATURE_FLAGS = [
      CYCLE_ANALYTICS_FEATURE_FLAG,
      PRODUCTIVITY_ANALYTICS_FEATURE_FLAG,
      REPORT_PAGES_FEATURE_FLAG
    ].freeze

    FEATURE_FLAG_DEFAULTS = {
      PRODUCTIVITY_ANALYTICS_FEATURE_FLAG => true,
      CYCLE_ANALYTICS_FEATURE_FLAG => true,
      REPORT_PAGES_FEATURE_FLAG => false
    }.freeze

    def self.any_features_enabled?
      FEATURE_FLAGS.any? { |flag| Feature.enabled?(flag, default_enabled: feature_enabled_by_default?(flag)) }
    end

    def self.cycle_analytics_enabled?
      feature_enabled?(CYCLE_ANALYTICS_FEATURE_FLAG)
    end

    def self.productivity_analytics_enabled?
      feature_enabled?(PRODUCTIVITY_ANALYTICS_FEATURE_FLAG)
    end

    def self.report_pages_enabled?
      feature_enabled?(REPORT_PAGES_FEATURE_FLAG)
    end

    def self.feature_enabled_by_default?(flag)
      !!FEATURE_FLAG_DEFAULTS[flag]
    end

    def self.feature_enabled?(feature)
      Feature.enabled?(feature, default_enabled: feature_enabled_by_default?(feature))
    end
  end
end
