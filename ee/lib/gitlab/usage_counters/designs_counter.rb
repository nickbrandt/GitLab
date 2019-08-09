# frozen_string_literal: true

module Gitlab::UsageCounters
  class DesignsCounter
    extend ::Gitlab::UsageDataCounters::RedisCounter

    KNOWN_EVENTS = %w[create update delete].map(&:freeze).freeze

    UnknownEvent = Class.new(StandardError)

    class << self
      # Each event gets a unique Redis key
      def redis_key(event)
        raise UnknownEvent, event unless KNOWN_EVENTS.include?(event.to_s)

        "USAGE_DESIGN_MANAGEMENT_DESIGNS_#{event}".upcase
      end

      def count(event)
        increment(redis_key event)
      end

      def read(event)
        total_count(redis_key event)
      end

      def totals
        KNOWN_EVENTS.map { |e| ["design_management_designs_#{e}".to_sym, read(e)] }.to_h
      end
    end
  end
end
