# frozen_string_literal: true

module Gitlab
  module SubscriptionPortal
    class Client
      def generate_trial(params)
        parse_response(Gitlab::HTTP.post("#{base_url}/trials",
                                         body: params.to_json,
                                         headers: headers))
      end

      private

      def base_url
        EE::SUBSCRIPTIONS_URL
      end

      def headers
        {
          "Accept" => 'application/json',
          'Content-Type' => 'application/json',
          "X-Admin-Email" => ENV['SUBSCRIPTION_PORTAL_ADMIN_EMAIL'],
          "X-Admin-Token" => ENV['SUBSCRIPTION_PORTAL_ADMIN_TOKEN']
        }
      end

      def parse_response(http_response)
        response = Hashie::Mash.new(success: false)

        case http_response.response
        when Net::HTTPSuccess
          response.success = true
          response.data = JSON.parse(http_response.body) rescue nil
        when Net::HTTPUnprocessableEntity
          response.data = JSON.parse(http_response.body) rescue nil
        else
          response.data = { errors: "HTTP status code: #{http_response.code}" }
        end

        response
      end
    end
  end
end
