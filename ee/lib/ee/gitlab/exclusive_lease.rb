# frozen_string_literal: true

module EE
  module Gitlab
    module ExclusiveLease
      # Try to obtain the lease. Returns the UUID and current TTL, which will be
      # zero if it's not taken.
      # rubocop: disable Gitlab/ModuleWithInstanceVariables
      def try_obtain_with_ttl
        ::Gitlab::Redis::SharedState.with do |redis|
          output = redis.set(@redis_shared_state_key, @uuid, nx: true, ex: @timeout) && @uuid

          ttl = output ? 0 : redis.ttl(@redis_shared_state_key)

          { ttl: [ttl, 0].max, uuid: output }
        end
      end
      # rubocop: enable Gitlab/ModuleWithInstanceVariables

      # Returns true if the UUID for the key hasn't changed.
      # rubocop: disable Gitlab/ModuleWithInstanceVariables
      def same_uuid?
        ::Gitlab::Redis::SharedState.with do |redis|
          redis.get(@redis_shared_state_key) == @uuid
        end
      end
      # rubocop: enable Gitlab/ModuleWithInstanceVariables
    end
  end
end
