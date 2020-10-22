# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  class LinkInput < BaseInputObject
    argument :url, type: GraphQL::STRING_TYPE, required: false,
      description: ""
  end
  # rubocop: enable Graphql/AuthorizeTypes
end
