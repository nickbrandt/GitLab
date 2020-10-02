# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  class TimeframeInputType < BaseInputObject
    graphql_name 'Timeframe'
    description 'A time-frame defined as a closed inclusive range of two points in time'

    argument :start, Types::TimeType,
             required: true,
             description: 'The start of the range'

    argument :end, Types::TimeType,
             required: true,
             description: 'The end of the range'

    def prepare
      if self[:end] < self[:start]
        raise ::Gitlab::Graphql::Errors::ArgumentError, 'start must be before end'
      end

      to_h
    end
  end
  # rubocop: enable Graphql/AuthorizeTypes
end
