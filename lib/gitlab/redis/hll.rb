# frozen_string_literal: true

module Gitlab
  module Redis
    class HLL
      KeyFormatError = Class.new(StandardError)

      def self.count(params)
        self.new.count(params)
      end

      def self.add(params)
        self.new.add(params)
      end

      def count(keys:)
        Gitlab::Redis::SharedState.with do |redis|
          redis.pfcount(*keys)
        end
      end

      def add(key:, value:, expiry:)
        unless %r{\A(\w|-|:)*\{\w*\}(\w|-|:)*\z}.match?(key)
          raise KeyFormatError.new("Invalid key format. #{key} key should have changeable parts in curly braces. See https://docs.gitlab.com/ee/development/redis.html#multi-key-commands")
        end

        Gitlab::Redis::SharedState.with do |redis|
          redis.multi do |multi|
            multi.pfadd(key, value)
            multi.expire(key, expiry)
          end
        end
      end
    end
  end
end
