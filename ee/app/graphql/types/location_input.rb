# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  class LocationInput < BaseInputObject
    argument :file, type: GraphQL::STRING_TYPE, required: false,
    description: ""
    argument :dependency, type: Types::DependencyInput, required: false,
  description: ""
    argument :blob_path, type: GraphQL::STRING_TYPE, required: false,
    description: ""
  end
  # rubocop: enable Graphql/AuthorizeTypes
end
