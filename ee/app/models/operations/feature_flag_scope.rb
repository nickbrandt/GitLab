# frozen_string_literal: true

module Operations
  class FeatureFlagScope < ActiveRecord::Base
    prepend HasEnvironmentScope

    self.table_name = 'operations_feature_flag_scopes'

    belongs_to :feature_flag

    validates :environment_scope, uniqueness: {
      scope: :feature_flag,
      message: "(%{value}) has already been taken"
    }

    scope :enabled, -> { where(active: true) }
    scope :disabled, -> { where(active: false) }
  end
end
