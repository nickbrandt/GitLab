# frozen_string_literal: true

namespace :analytics do
  root to: 'analytics#index'

  constraints(::Constraints::FeatureConstrainer.new(Gitlab::Analytics::PRODUCTIVITY_ANALYTICS_FEATURE_FLAG)) do
    resource :productivity_analytics, only: :show
  end

  constraints(::Constraints::FeatureConstrainer.new(Gitlab::Analytics::CYCLE_ANALYTICS_FEATURE_FLAG)) do
    resource :cycle_analytics, only: :show
    namespace :cycle_analytics do
      resources :stages, only: [:index]
    end
  end

  constraints(::Constraints::FeatureConstrainer.new(Gitlab::Analytics::TASKS_BY_TYPE_CHART_FEATURE_FLAG)) do
    scope :type_of_work do
      resource :tasks_by_type, controller: :tasks_by_type, only: :show
    end
  end

  constraints(::Constraints::FeatureConstrainer.new(Gitlab::Analytics::CODE_ANALYTICS_FEATURE_FLAG)) do
    resource :code_analytics, only: :show
  end
end
