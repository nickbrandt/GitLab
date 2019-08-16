# frozen_string_literal: true

class Plan < ApplicationRecord
  # This constant must keep ordered by tier.
  PAID_HOSTED_PLANS = %w[bronze silver gold].freeze
  ALL_HOSTED_PLANS = (PAID_HOSTED_PLANS + ['early_adopter']).freeze

  has_many :namespaces
  has_many :hosted_subscriptions, class_name: 'GitlabSubscription', foreign_key: 'hosted_plan_id'

  def self.hosted_plans_for_namespaces(namespaces)
    namespaces = Array(namespaces)

    Plan
      .joins(:hosted_subscriptions)
      .where(name: ALL_HOSTED_PLANS)
      .where(gitlab_subscriptions: { namespace_id: namespaces })
      .distinct
  end
end
