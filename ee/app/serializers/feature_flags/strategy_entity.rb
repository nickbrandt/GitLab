# frozen_string_literal: true

module FeatureFlags
  class StrategyEntity < Grape::Entity
    expose :id
    expose :name
    expose :parameters
    expose :scopes, with: FeatureFlags::ScopeEntity
  end
end
