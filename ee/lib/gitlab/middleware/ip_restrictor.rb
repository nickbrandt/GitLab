# frozen_string_literal: true

module Gitlab
  module Middleware
    class IpRestrictor
      def initialize(app)
        @app = app
      end

      def call(env)
        return @app.call(env) if env['PATH_INFO'] =~ %r{^/api/v\d+/internal/}

        ::Gitlab::IpAddressState.with(env['action_dispatch.remote_ip'].to_s) do # rubocop: disable CodeReuse/ActiveRecord
          @app.call(env)
        end
      end
    end
  end
end
