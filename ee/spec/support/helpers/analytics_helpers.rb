# frozen_string_literal: true

# Helper for analytics related features
module AnalyticsHelpers
  def disable_all_analytics_feature_flags
    Gitlab::Analytics::FEATURE_FLAGS.each do |flag|
      stub_feature_flags(flag => false)
    end
  end

  def enable_only_one_analytics_feature_flag
    Gitlab::Analytics::FEATURE_FLAGS.each_with_index do |flag, i|
      stub_feature_flags(flag => i == 0)
    end
  end
end
