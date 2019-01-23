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

    scope :ordered, -> { order(:name) }
    scope :enabled, -> { where(active: true) }
    scope :disabled, -> { where(active: false) }

    scope :for_environment, -> (environment) do
      select("operations_feature_flags.*" \
             ", (#{actual_active_sql(environment)}) AS active")
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
    end

    def strategies
      [
        { name: 'default' }
      ]
    end
  end
end
