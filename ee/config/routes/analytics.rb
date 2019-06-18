# frozen_string_literal: true

namespace :analytics do
  root to: redirect('-/analytics/productivity_analytics')

  resource :productivity_analytics, only: :show
  resource :cycle_analytics, only: :show
end
