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
                description: 'The color palette to assign to the on-call user. i.e blue. For easy identification of the user when displaying in a UI.'

      field :color_weight, GraphQL::STRING_TYPE,
                null: true,
                description: 'The color weight to assign to for the on-call user. i.e 500. For easy identification of the user when displaying in a UI.'
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
