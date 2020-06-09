# frozen_string_literal: true

module Types
  class GlobalIDType < GraphQL::Schema::Scalar
    description "A wrapper for GraphQL IDs"

    # @param value [GID]
    # @return [String]
    def self.coerce_result(value, _ctx)
      value.to_s
    end

    # @param value [String]
    # @return [GID]
    def self.coerce_input(value, _ctx)
      GlobalID.parse(value.to_s)
    rescue ArgumentError, TypeError
      # Invalid input
      nil
    end
  end
end
