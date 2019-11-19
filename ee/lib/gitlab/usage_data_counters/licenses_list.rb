# frozen_string_literal: true

module Gitlab
  module UsageDataCounters
    class LicensesList < BaseCounter
      KNOWN_EVENTS = %w[views].freeze
      PREFIX = 'licenses_list'
    end
  end
end
