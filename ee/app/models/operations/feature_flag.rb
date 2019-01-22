# frozen_string_literal: true

module Operations
  ##
  # NOTE:
  # "operations_feature_flags.active" column is not used in favor of
  # operations_feature_flag_scopes's override policy.
  # You can calculate actual `active` values with `for_environment` method.
  class FeatureFlag < ActiveRecord::Base
    self.table_name = 'operations_feature_flags'

    belongs_to :project

    has_many :scopes, class_name: 'Operations::FeatureFlagScope'
    has_one :default_scope, -> { where(environment_scope: '*') }, class_name: 'Operations::FeatureFlagScope'

    validates :project, presence: true
    validates :name,
      presence: true,
      length: 2..63,
      format: {
        with: Gitlab::Regex.feature_flag_regex,
        message: Gitlab::Regex.feature_flag_regex_message
      }
    validates :name, uniqueness: { scope: :project_id }
    validates :description, allow_blank: true, length: 0..255

    before_create :build_default_scope
    after_update :update_default_scope

    accepts_nested_attributes_for :scopes, allow_destroy: true

    scope :ordered, -> { order(:name) }

    scope :enabled, -> do
      if Feature.enabled?(:feature_flags_environment_scope)
        where('EXISTS (?)', join_enabled_scopes)
      else
        where(active: true)
      end
    end

    scope :disabled, -> do
      if Feature.enabled?(:feature_flags_environment_scope)
        where('NOT EXISTS (?)', join_enabled_scopes)
      else
        where(active: false)
      end
    end

    scope :for_environment, -> (environment) do
      select("operations_feature_flags.*" \
             ", (#{actual_active_sql(environment)}) AS active")
    end

    scope :for_list, -> do
      select("operations_feature_flags.*" \
             ", COALESCE((#{join_enabled_scopes.to_sql}), FALSE) AS active")
    end

    class << self
      def actual_active_sql(environment)
        Operations::FeatureFlagScope
          .where('operations_feature_flag_scopes.feature_flag_id = ' \
                 'operations_feature_flags.id')
          .on_environment(environment, relevant_only: true)
          .select('active')
          .to_sql
      end

      def join_enabled_scopes
        Operations::FeatureFlagScope
          .where('operations_feature_flags.id = feature_flag_id')
          .enabled.limit(1).select('TRUE')
      end

      def preload_relations
        preload(:scopes)
      end
    end

    def strategies
      [
        { name: 'default' }
      ]
    end

    private

    def build_default_scope
      scopes.build(environment_scope: '*', active: self.active)
    end

    def update_default_scope
      default_scope.update(active: self.active) if self.active_changed?
    end
  end
end
