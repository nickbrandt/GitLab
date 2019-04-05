# frozen_string_literal: true

module EE
  module Gitlab
    module Scim
      class ProvisioningResponse
        attr_reader :status, :message, :identity

        def initialize(status:, message: nil, identity: nil)
          @status = status
          @message = message
          @identity = identity
        end
      end
    end
  end
end
