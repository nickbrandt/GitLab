# frozen_string_literal: true

module Gitlab
  module SubscriptionPortal
    class Client
      def generate_trial(params)
        response = Gitlab::HTTP.post("#{base_url}/trials", body: params.to_json, headers: headers)

        parse_response(response)
      rescue *Gitlab::HTTP::HTTP_ERRORS => e
        { success: false, data: { errors: e.message } }
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
        response = { success: false }

        case http_response.response
        when Net::HTTPSuccess
          response[:success] = true
          response[:data] = http_response.parsed_response
        when Net::HTTPUnprocessableEntity
          response[:data] = http_response.parsed_response
        else
          response[:data] = { errors: "HTTP status code: #{http_response.code}" }
        end

        response
      end
    end
  end
end
