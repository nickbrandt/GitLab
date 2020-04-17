# frozen_string_literal: true

module Types
  class ListType < BaseObject
    graphql_name 'List'
    description 'Represents a list within a board'

    authorize :read_list

    field :id, type: GraphQL::ID_TYPE, null: false,
          description: 'ID (global ID) of the list'
  end
end
