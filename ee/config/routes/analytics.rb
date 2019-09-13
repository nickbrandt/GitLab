# frozen_string_literal: true

namespace :analytics do
  root to: 'analytics#index'

  constraints(::Constraints::FeatureConstrainer.new(Gitlab::Analytics::PRODUCTIVITY_ANALYTICS_FEATURE_FLAG)) do
    resource :productivity_analytics, only: :show
  end

  constraints(::Constraints::FeatureConstrainer.new(Gitlab::Analytics::CYCLE_ANALYTICS_FEATURE_FLAG)) do
    resource :cycle_analytics, only: :show
  end
end
