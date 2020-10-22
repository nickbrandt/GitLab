# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  class FixInput < BaseInputObject
    argument :cve, type: GraphQL::STRING_TYPE, required: false,
    description: ""
    argument :id, type: GraphQL::STRING_TYPE, required: false,
    description: ""
  end
  # rubocop: enable Graphql/AuthorizeTypes
end
