# frozen_string_literal: true

module Operations
  class FeatureFlagScope < ApplicationRecord
    prepend HasEnvironmentScope
    include Gitlab::Utils::StrongMemoize

    self.table_name = 'operations_feature_flag_scopes'

    belongs_to :feature_flag

    validates :environment_scope, uniqueness: {
      scope: :feature_flag,
      message: "(%{value}) has already been taken"
    }

    validates :environment_scope,
      if: :default_scope?, on: :update,
      inclusion: { in: %w(*), message: 'cannot be changed from default scope' }

    validates :strategies, feature_flag_strategies: true

    before_destroy :prevent_destroy_default_scope, if: :default_scope?

    scope :ordered, -> { order(:id) }
    scope :enabled, -> { where(active: true) }
    scope :disabled, -> { where(active: false) }

    def self.with_name_and_description
      joins(:feature_flag)
        .select(FeatureFlag.arel_table[:name], FeatureFlag.arel_table[:description])
    end

    def self.for_unleash_client(project, environment)
      select('DISTINCT ON (operations_feature_flag_scopes.feature_flag_id) operations_feature_flag_scopes.*')
        .with_name_and_description
        .where(feature_flag_id: project.operations_feature_flags.select(:id))
        .order(:feature_flag_id)
        .on_environment(environment)
        .reverse_order
    end

    private

    def default_scope?
      environment_scope_was == '*'
    end

    def prevent_destroy_default_scope
      raise ActiveRecord::ReadOnlyRecord, "default scope cannot be destroyed"
    end
  end
end
