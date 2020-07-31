# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  class IssuableConnectionType < GraphQL::Types::Relay::BaseConnection
    field :count, Integer, null: false,
          description: 'Total count of collection'

    def count
      relation = object.items

      if relation.try(:group_values)&.present?
        relation.size.keys.size
      else
        relation.size
      end
    end
  end
end
