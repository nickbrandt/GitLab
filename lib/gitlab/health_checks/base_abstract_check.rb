# frozen_string_literal: true

module Gitlab
  module HealthChecks
    module BaseAbstractCheck
      def name
        super.demodulize.underscore
      end

      def human_name
        name.sub(/_check$/, '').capitalize
      end

      def readiness
        raise NotImplementedError
      end

      def metrics
        []
      end

      protected

      def metric(name, value, **labels)
        Metric.new(name, value, labels)
      end

      def with_timing
        start = Time.current
        result = yield
        [result, Time.current.to_f - start.to_f]
      end

      def catch_timeout(seconds, &block)
        Timeout.timeout(seconds.to_i, &block)
      rescue Timeout::Error => ex
        ex
      end
    end
  end
end
