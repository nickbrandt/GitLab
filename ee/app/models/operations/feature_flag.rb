# frozen_string_literal: true

module Operations
  class FeatureFlag < ApplicationRecord
    self.table_name = 'operations_feature_flags'

    belongs_to :project

    default_value_for :active, true

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
    validate :first_default_scope, on: :create, if: :has_scopes?

    before_create :build_default_scope, unless: :has_scopes?

    accepts_nested_attributes_for :scopes, allow_destroy: true

    scope :ordered, -> { order(:name) }

    scope :enabled, -> { where(active: true) }
    scope :disabled, -> { where(active: false) }

    class << self
      def preload_relations
        preload(:scopes)
      end
    end

    private

    def first_default_scope
      unless scopes.first.environment_scope == '*'
        errors.add(:default_scope, 'has to be the first element')
      end
    end

    def build_default_scope
      scopes.build(environment_scope: '*', active: self.active)
    end

    def has_scopes?
      scopes.any?
    end
  end
end
