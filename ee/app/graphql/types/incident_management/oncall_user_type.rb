# frozen_string_literal: true

module Types
  module IncidentManagement
    # rubocop: disable Graphql/AuthorizeTypes
    class OncallUserType < BaseObject
      graphql_name 'OncallUserType'
      description 'The rotation user and color palette'

      field :user, Types::UserType,
                null: false,
                description: 'The user who is participating'

      field :color_palette, GraphQL::STRING_TYPE,
                null: true,
                description: 'The color palette for the user'

      field :color_weight, GraphQL::STRING_TYPE,
                null: true,
                description: 'The color weight for the user'
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
