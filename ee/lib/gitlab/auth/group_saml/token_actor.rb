# frozen_string_literal: true

module Gitlab
  module Auth
    module GroupSaml
      class TokenActor
        def initialize(token)
          @token = token
        end

        def valid_for?(group)
          group.saml_discovery_token.present? && group.saml_discovery_token == @token
        end
      end
    end
  end
end
