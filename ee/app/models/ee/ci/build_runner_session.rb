# frozen_string_literal: true

module EE
  module Ci
    module BuildRunnerSession
      extend ActiveSupport::Concern

      DEFAULT_SERVICE_NAME = 'build'.freeze
      DEFAULT_PORT_NAME = 'default_port'.freeze

      def service_specification(service: nil, path: nil, port: nil, subprotocols: nil)
        return {} unless url.present?

        port = port.presence || DEFAULT_PORT_NAME
        service = service.presence || DEFAULT_SERVICE_NAME
        url = "#{self.url}/proxy/#{service}/#{port}/#{path}"
        subprotocols = subprotocols.presence || ::Ci::BuildRunnerSession::TERMINAL_SUBPROTOCOL

        channel_specification(url, subprotocols)
      end
    end
  end
end
