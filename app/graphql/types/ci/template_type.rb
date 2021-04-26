# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes
    class TemplateType < BaseObject
      graphql_name 'CiTemplate'
      description 'GitLab CI config template.'

      field :name, GraphQL::STRING_TYPE, null: false,
        description: 'Name of the CI template.'
      field :content, GraphQL::STRING_TYPE, null: false,
        description: 'Contents of the CI template.'
    end
  end
end
