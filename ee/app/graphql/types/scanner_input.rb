# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  class ScannerInput < BaseInputObject
    argument :id, type: GraphQL::INT_TYPE, required: false,
    description: ""
    argument :name, type: GraphQL::STRING_TYPE, required: false,
  description: ""
    argument :full_path, type: GraphQL::STRING_TYPE, required: false,
  description: ""
    argument :full_name, type: GraphQL::STRING_TYPE, required: false,
    description: ""
  end
  # rubocop: enable Graphql/AuthorizeTypes
end
