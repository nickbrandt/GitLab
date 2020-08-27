# frozen_string_literal: true

module Types
  class ErrorExtensionsType < BaseObject # rubocop:disable Graphql/AuthorizeTypes
    graphql_name 'ErrorExtensions'

    field :code, GraphQL::STRING_TYPE, null: false, description: 'Error Code'
  end
end
