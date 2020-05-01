# frozen_string_literal: true

module Gitlab
  module ExclusiveLeaseHelpers
    # Wrapper around ExclusiveLease that adds retry logic
    class SleepingLock
      attr_reader :attempts

      delegate :cancel, to: :@lease

      def initialize(key, timeout:, delay:)
        @lease = ::Gitlab::ExclusiveLease.new(key, timeout: timeout)
        @delay = delay
        @attempts = 0
      end

      def obtain(max_attempts)
        until held?
          raise FailedToObtainLockError, 'Failed to obtain a lock' if attempts >= max_attempts

          sleep(sleep_sec) unless first_attempt?
          try_obtain
        end
      end

      private

      attr_reader :delay

      def held?
        @uuid.present?
      end

      def try_obtain
        @uuid ||= @lease.try_obtain
        @attempts += 1
      end

      def first_attempt?
        attempts.zero?
      end

      def sleep_sec
        delay.respond_to?(:call) ? delay.call(attempts) : delay
      end
    end
  end
end
