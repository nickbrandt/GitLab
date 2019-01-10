# frozen_string_literal: true

module FeatureFlagHelpers
  def create_scope(feature_flag, environment_scope, active)
    create(:operations_feature_flag_scope,
      feature_flag: feature_flag,
      environment_scope: environment_scope,
      active: active)
  end
end
