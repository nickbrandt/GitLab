# frozen_string_literal: true

module Gitlab
  class IpAddressState
    THREAD_KEY = :current_ip_address

    class << self
      def with(address)
        self.current = address
        yield
      ensure
        self.current = nil
      end

      def current
        Thread.current[THREAD_KEY]
      end

      protected

      def current=(value)
        Thread.current[THREAD_KEY] = value
      end
    end
  end
end
