# frozen_string_literal: true

namespace :analytics do
  constraints(::Constraints::FeatureConstrainer.new(:productivity_analytics)) do
    root to: redirect('-/analytics/productivity_analytics')

    resource :productivity_analytics, only: :show
  end

  constraints(::Constraints::FeatureConstrainer.new(:cycle_analytics)) do
    resource :cycle_analytics, only: :show
  end
end
