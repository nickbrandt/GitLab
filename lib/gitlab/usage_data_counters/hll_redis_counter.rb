# frozen_string_literal: true

module Gitlab
  module UsageDataCounters
    class HLLRedisCounter
      KEY_EXPIRY_LENGTH = 6.weeks
      UnknownEvent = Class.new(StandardError)

      REDIS_SLOT = ''.freeze

      def track_event(entity_id, event, time = Time.zone.now)
        key = redis_key(event, time)

        Gitlab::Redis::HLL.add(key: key, value: entity_id, expiry: expiry)
      end

      # Returns number of unique users for given events in given time frame
      #
      # @param [String, Array[<String>]] events to count on.
      # @param [ActiveSupport::TimeWithZone] start_week start of time frame
      # @param [Integer] weeks time frame length in weeks
      # @return [Integer] number of unique users
      def unique_events(events:, start_week: Time.zone.now, weeks: 4)
        timeframe_start = [start_week, weeks.weeks.ago].min
        keys = redis_keys(events: Array(events), timeframe_start: timeframe_start, weeks: weeks)

        Gitlab::Redis::HLL.count(keys: keys)
      end

      def known_events
        self.class::KNOWN_EVENTS
      end

      def expiry
        self.class::KEY_EXPIRY_LENGTH
      end

      private

      def redis_slot
        self.class::REDIS_SLOT
      end

      def redis_key(event, time)
        raise UnknownEvent.new("Unknown event #{event}") unless known_events.include?(event.to_s)

        key = if redis_slot.present?
                event.to_s.gsub(redis_slot, "{#{redis_slot}}")
              else
                "{#{event}}"
              end

        year_week = time.strftime('%G-%V')
        "#{key}-#{year_week}"
      end

      def redis_keys(events:, timeframe_start:, weeks:)
        (0..(weeks - 1)).map do |week_increment|
          events.map { |event| redis_key(event, timeframe_start + week_increment * 7.days) }
        end.flatten
      end
    end
  end
end
