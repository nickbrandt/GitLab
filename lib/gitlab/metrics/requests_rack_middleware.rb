# frozen_string_literal: true

module Gitlab
  module Metrics
    class RequestsRackMiddleware
      HTTP_METHODS = %w(delete get head options patch post put trace).freeze
      STATUSES = %w(200 301 304 400 401 403 404 500).freeze

      def initialize(app)
        @app = app
      end

      def self.http_request_total
        @http_request_total ||= ::Gitlab::Metrics.counter(:http_requests_total, 'Request count')
      end

      def self.rack_uncaught_errors_count
        @rack_uncaught_errors_count ||= ::Gitlab::Metrics.counter(:rack_uncaught_errors_total, 'Request handling uncaught errors count')
      end

      def self.http_request_duration_seconds
        @http_request_duration_seconds ||= ::Gitlab::Metrics.histogram(:http_request_duration_seconds, 'Request handling execution time',
                                                           {}, [0.05, 0.1, 0.25, 0.5, 0.7, 1, 2.5, 5, 10, 25])
      end

      def self.initialize_http_request_duration_seconds
        HTTP_METHODS.each do |method|
          STATUSES.each do |status|
            http_request_duration_seconds.get({ method: method, status: status })
          end
        end
      end

      def call(env)
        method = env['REQUEST_METHOD'].downcase
        started = Time.now.to_f
        begin
          RequestsRackMiddleware.http_request_total.increment(method: method)

          status, headers, body = @app.call(env)

          elapsed = Time.now.to_f - started
          RequestsRackMiddleware.http_request_duration_seconds.observe({ method: method, status: status }, elapsed)

          [status, headers, body]
        rescue
          RequestsRackMiddleware.rack_uncaught_errors_count.increment
          raise
        end
      end
    end
  end
end
