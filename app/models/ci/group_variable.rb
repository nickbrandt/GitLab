# frozen_string_literal: true

module Ci
  class GroupVariable < ApplicationRecord
    extend Gitlab::Ci::Model
    include Ci::HasVariable
    include Presentable
    include Ci::Maskable
    prepend HasEnvironmentScope

    belongs_to :group, class_name: "::Group"

    alias_attribute :secret_value, :value

    validates :key, uniqueness: {
      scope: [:group_id, :environment_scope],
      message: "(%{value}) has already been taken"
    }, if: :ci_group_variable_environment_scope_enabled?

    validates :key, uniqueness: {
      scope: [:group_id],
      message: "(%{value}) has already been taken"
    }, unless: :ci_group_variable_environment_scope_enabled?

    scope :unprotected, -> { where(protected: false) }

    private

    def ci_group_variable_environment_scope_enabled?
      Feature.enabled?(:ci_group_variable_environment_scope, group)
    end
  end
end
