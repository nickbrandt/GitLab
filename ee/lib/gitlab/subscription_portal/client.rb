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
          'Accept' => 'application/json',
          'Content-Type' => 'application/json',
          'X-Admin-Email' => ENV['SUBSCRIPTION_PORTAL_ADMIN_EMAIL'],
          'X-Admin-Token' => ENV['SUBSCRIPTION_PORTAL_ADMIN_TOKEN']
        }
      end

      def parse_response(http_response)
        parsed_response = http_response.parsed_response

        case http_response.response
        when Net::HTTPSuccess
          { success: true, data: parsed_response }
        when Net::HTTPUnprocessableEntity
          { success: false, data: { errors: parsed_response['errors'] } }
        else
          { success: false, data: { errors: "HTTP status code: #{http_response.code}" } }
        end
      end
    end
  end
end
