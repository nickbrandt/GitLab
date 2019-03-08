# frozen_string_literal: true

module InsightsFeature
  extend ActiveSupport::Concern

  # This allows to:
  #   1. Disable the :insights by default even if the license allows it
  #   1. Enable the Insights feature for an arbitrary group/project
  # Once we're ready to release the feature, we could just replace
  # `{group,project}.insights_available?` with
  # `{group,project}.feature_available?(:insights)` and remove this module.
  def insights_available?
    ::Feature.enabled?(:insights, self) && feature_available?(:insights)
  end
end
