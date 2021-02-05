# frozen_string_literal: true

module Gitlab::UsageDataCounters
  class ProjectIntegrationActivityCounter < BaseCounter
    KNOWN_EVENTS = %w[slack].freeze
    PREFIX = 'project_integration_activity'
  end
end
