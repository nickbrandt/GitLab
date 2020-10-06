# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  module RangeInputType
    def self.[](type, closed = true)
      Class.new(BaseInputObject) do
        argument :start, type,
                 required: closed,
                 description: 'The start of the range'

        argument :end, type,
                 required: closed,
                 description: 'The end of the range'

        def prepare
          if self[:end] && self[:start] && self[:end] < self[:start]
            raise ::Gitlab::Graphql::Errors::ArgumentError, 'start must be before end'
          end

          to_h
        end
      end
    end
  end
  # rubocop: enable Graphql/AuthorizeTypes
end
