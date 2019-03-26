# frozen_string_literal: true

module EE
  module Gitlab
    module Scim
      class Error < Grape::Entity
        expose :schemas
        expose :detail, safe: true
        expose :status

        private

        DEFAULT_SCHEMA = 'urn:ietf:params:scim:api:messages:2.0:Error'

        def schemas
          [DEFAULT_SCHEMA]
        end

        def status
          409
        end
      end
    end
  end
end
