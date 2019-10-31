# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  class EpicDescendantCountType < BaseObject
    graphql_name 'EpicDescendantCount'

    field :opened_epics, GraphQL::INT_TYPE, null: true, description: 'Number of opened sub-epics'
    field :closed_epics, GraphQL::INT_TYPE, null: true, description: 'Number of closed sub-epics'
    field :opened_issues, GraphQL::INT_TYPE, null: true, description: 'Number of opened epic issues'
    field :closed_issues, GraphQL::INT_TYPE, null: true, description: 'Number of closed epic issues'
  end
  # rubocop: enable Graphql/AuthorizeTypes
end
