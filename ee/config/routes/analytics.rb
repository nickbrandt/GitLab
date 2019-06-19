# frozen_string_literal: true

namespace :analytics do
  root to: redirect('-/analytics/productivity_analytics')

  resource :productivity_analytics, only: :show
  resource :cycle_analytics, only: :show
  scope :events, controller: 'cycle_analytics_events' do
    get :issue
    get :plan
    get :code
    get :test
    get :review
    get :staging
    get :production
  end
end
