# frozen_string_literal: true

namespace :analytics do
  root to: 'analytics#index'

  constraints(::Constraints::FeatureConstrainer.new(:productivity_analytics)) do
    resource :productivity_analytics, only: :show
  end

  constraints(::Constraints::FeatureConstrainer.new(:cycle_analytics)) do
    resource :cycle_analytics, only: :show
  end
end
