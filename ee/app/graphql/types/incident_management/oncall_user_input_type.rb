# frozen_string_literal: true

module Types
  module IncidentManagement
    # rubocop: disable Graphql/AuthorizeTypes
    class OncallUserInputType < BaseInputObject
      graphql_name 'OncallUserInputType'
      description 'The rotation user and color palette'

      argument :username, GraphQL::STRING_TYPE,
                required: true,
                description: 'The username of the user to participate in the on-call rotation'

      argument :color_palette, GraphQL::STRING_TYPE,
                required: false,
                description: 'The color palette for the user'

      argument :color_weight, GraphQL::STRING_TYPE,
                required: false,
                description: 'The color weight for the user'
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
