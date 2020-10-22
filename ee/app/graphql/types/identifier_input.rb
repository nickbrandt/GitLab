# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  class IdentifierInput < BaseInputObject
    argument :external_type, type: GraphQL::STRING_TYPE, required: false,
    description: ""
    argument :external_id, type: GraphQL::STRING_TYPE, required: false,
    description: ""
    argument :name, type: GraphQL::STRING_TYPE, required: false,
    description: ""
    argument :url, type: GraphQL::STRING_TYPE, required: false,
    description: ""
  end
  # rubocop: enable Graphql/AuthorizeTypes
end
