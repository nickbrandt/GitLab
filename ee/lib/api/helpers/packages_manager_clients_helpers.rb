# frozen_string_literal: true

module API
  module Helpers
    module PackagesManagerClientsHelpers
      include ::API::Helpers::PackagesHelpers

      def find_personal_access_token_from_http_basic_auth
        return unless headers

        encoded_credentials = headers['Authorization'].to_s.split('Basic ', 2).second
        token = Base64.decode64(encoded_credentials || '').split(':', 2).second

        return unless token

        PersonalAccessToken.find_by_token(token)
      end
    end
  end
end
