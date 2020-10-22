# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  class RemediationInput < BaseInputObject
    argument :fixes, type: [Types::FixInput], required: false,
    description: ""
    argument :summary, type: GraphQL::STRING_TYPE, required: false,
    description: ""
    argument :diff, type: GraphQL::STRING_TYPE, required: false,
    description: ""
  end
  # rubocop: enable Graphql/AuthorizeTypes
end
