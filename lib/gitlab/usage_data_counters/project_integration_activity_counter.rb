# frozen_string_literal: true

module Gitlab::UsageDataCounters
  class ProjectIntegrationActivityCounter < BaseCounter
    KNOWN_EVENTS = %w[slack mattermost].freeze
    PREFIX = 'project_integration_activity'
  end
end
