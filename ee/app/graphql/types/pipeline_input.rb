# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  class PipelineInput < BaseInputObject
    argument :id, type: GraphQL::INT_TYPE, required: false,
  description: ""
    argument :created_at, type: GraphQL::STRING_TYPE, required: false,
  description: ""
    argument :url, type: GraphQL::STRING_TYPE, required: false,
  description: ""
    argument :source_branch, type: GraphQL::STRING_TYPE, required: false,
    description: ""
  end
  # rubocop: enable Graphql/AuthorizeTypes
end
