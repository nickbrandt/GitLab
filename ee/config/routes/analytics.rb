# frozen_string_literal: true

namespace :analytics do
  root to: 'analytics#index'

  resource :productivity_analytics, only: :show, constraints: -> (req) { Gitlab::Analytics.productivity_analytics_enabled? }

  constraints(-> (req) { Gitlab::Analytics.cycle_analytics_enabled? }) do
    resource :cycle_analytics, only: :show
    namespace :cycle_analytics do
      resources :stages, only: [:index, :create, :update, :destroy] do
        member do
          get :duration_chart
          get :median
          get :records
        end
      end
      resource :summary, controller: :summary, only: [:show]
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
