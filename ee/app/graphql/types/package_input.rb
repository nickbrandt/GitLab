# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  class PackageInput < BaseInputObject
    argument :name, type: GraphQL::STRING_TYPE, required: false,
 description: ""
  end
  # rubocop: enable Graphql/AuthorizeTypes
end
