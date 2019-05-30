# frozen_string_literal: true

module Atlassian
  module JiraConnect
    class Client < Gitlab::HTTP
      def initialize(base_uri, shared_secret)
        @base_uri = base_uri
        @shared_secret = shared_secret
      end

      def store_dev_info(dev_info_json)
        uri = URI.join(@base_uri, '/rest/devinfo/0.10/bulk')

        headers = {
          'Authorization' => "JWT #{jwt_token('POST', uri)}",
          'Content-Type' => 'application/json'
        }

        self.class.post(uri, headers: headers, body: dev_info_json)
      end

      private

      def jwt_token(http_method, uri)
        claims = Atlassian::Jwt.build_claims(
          issuer: Atlassian::JiraConnect.app_key,
          method: http_method,
          uri: uri,
          base_uri: @base_uri
        )

        Atlassian::Jwt.encode(claims, @shared_secret)
      end
    end
  end
end
