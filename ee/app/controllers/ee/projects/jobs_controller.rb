# frozen_string_literal: true

module EE
  module Projects
    module JobsController
      extend ActiveSupport::Concern

      prepended do
        before_action :authorize_create_proxy_build!, only: :proxy_websocket_authorize
        before_action :verify_proxy_request!, only: :proxy_websocket_authorize
      end

      def proxy_websocket_authorize
        render json: proxy_websocket_service(build_service_specification)
      end

      private

      def authorize_create_proxy_build!
        return access_denied! unless can?(current_user, :create_build_service_proxy, build)
      end

      def verify_proxy_request!
        ::Gitlab::Workhorse.verify_api_request!(request.headers)
        set_workhorse_internal_api_content_type
      end

      # This method provides the information to Workhorse
      # about the service we want to proxy to.
      # For security reasons, in case this operation is started by JS,
      # it's important to use only sourced GitLab JS code
      def proxy_websocket_service(service)
        service[:url] = ::Gitlab::UrlHelpers.as_wss(service[:url])

        ::Gitlab::Workhorse.channel_websocket(service)
      end

      def build_service_specification
        build.service_specification(service: params['service'],
                                    port: params['port'],
                                    path: params['path'],
                                    subprotocols: proxy_subprotocol)
      end

      def proxy_subprotocol
        # This will allow to reuse the same subprotocol set
        # in the original websocket connection
        request.headers['HTTP_SEC_WEBSOCKET_PROTOCOL'].presence || ::Ci::BuildRunnerSession::TERMINAL_SUBPROTOCOL
      end
    end
  end
end
