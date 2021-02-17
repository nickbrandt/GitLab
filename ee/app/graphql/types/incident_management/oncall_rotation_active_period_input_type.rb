# frozen_string_literal: true

module Types
  module IncidentManagement
    # rubocop: disable Graphql/AuthorizeTypes
    class OncallRotationActivePeriodInputType < BaseInputObject
      graphql_name 'OncallRotationActivePeriodInputType'
      description 'Active period time range for on-call rotation'

      argument :start_time, GraphQL::STRING_TYPE,
                required: true,
                description: 'The start of the rotation active period.'

      argument :end_time, GraphQL::STRING_TYPE,
                required: true,
                description: 'The end of the rotation active period..'

      TIME_FORMAT = %r[^(0[0-9]|1[0-9]|2[0-3]):[0-5][0-9]$].freeze

      def prepare
        raise invalid_time_error unless TIME_FORMAT.match?(start_time)
        raise invalid_time_error unless TIME_FORMAT.match?(end_time)

        parsed_from = Time.parse(start_time)
        parsed_to = Time.parse(end_time)

        if parsed_to < parsed_from
          raise ::Gitlab::Graphql::Errors::ArgumentError, "'start_time' time must be before 'end_time' time"
        end

        to_h
      end

      private

      def invalid_time_error
        ::Gitlab::Graphql::Errors::ArgumentError.new 'Time given is invalid'
      end
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
