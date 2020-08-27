# frozen_string_literal: true

module Types
  class ErrorType < BaseObject # rubocop:disable Graphql/AuthorizeTypes
    graphql_name 'Error'

    field :message, GraphQL::STRING_TYPE, null: false, description: 'Error Message'
    field :path, [GraphQL::STRING_TYPE], null: false, description: 'Error Path'
    field :extensions, ErrorExtensionsType, null: false, description: 'Error Extensions'
  end
end
