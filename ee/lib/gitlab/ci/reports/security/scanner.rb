# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Security
        class Scanner
          attr_accessor :external_id, :name, :vendor

          def initialize(external_id:, name:, vendor:)
            @external_id = external_id
            @name = name
            @vendor = vendor
          end

          def key
            external_id
          end

          def to_hash
            %i[
              external_id
              name
              vendor
            ].each_with_object({}) do |key, hash|
              hash[key] = public_send(key).to_s # rubocop:disable GitlabSecurity/PublicSend
            end
          end

          def ==(other)
            other.external_id == external_id
          end
        end
      end
    end
  end
end
