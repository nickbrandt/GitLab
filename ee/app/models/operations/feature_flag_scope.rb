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

    validates :environment_scope,
      if: :default_scope?, on: :update,
      inclusion: { in: %w(*), message: 'cannot be changed from default scope' }

    before_destroy :prevent_destroy_default_scope, if: :default_scope?

    scope :ordered, -> { order(:id) }
    scope :enabled, -> { where(active: true) }
    scope :disabled, -> { where(active: false) }

    private

    def default_scope?
      environment_scope_was == '*'
    end

    def prevent_destroy_default_scope
      raise ActiveRecord::ReadOnlyRecord, "default scope cannot be destroyed"
    end
  end
end
