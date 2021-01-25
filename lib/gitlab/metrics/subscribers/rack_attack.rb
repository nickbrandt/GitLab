# frozen_string_literal: true

module Gitlab
  module Metrics
    module Subscribers
      # Instrument the cache operations of RackAttack to use in structured
      # logs. Two fields are exposed:
      # - rack_attack_redis_count: the number of redis calls triggered by
      # RackAttack in a request.
      # - rack_attack_redis_duration_s: the total duration of all redis calls
      # triggered by RackAttack in a request.
      class RackAttack < ActiveSupport::Subscriber
        attach_to 'rack_attack'

        INSTRUMENTATION_STORE_KEY = :rack_attack_instrumentation

        PAYLOAD_KEYS = [
          :rack_attack_redis_count,
          :rack_attack_redis_duration_s
        ].freeze

        def self.payload
          Gitlab::SafeRequestStore[INSTRUMENTATION_STORE_KEY] ||= {
            rack_attack_redis_count: 0,
            rack_attack_redis_duration_s: 0.0
          }
        end

        def redis(event)
          self.class.payload[:rack_attack_redis_count] += 1
          self.class.payload[:rack_attack_redis_duration_s] += event.duration.to_f / 1000
        end
      end
    end
  end
end
