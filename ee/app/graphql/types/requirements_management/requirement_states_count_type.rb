# frozen_string_literal: true

module Types
  module RequirementsManagement
    # rubocop: disable Graphql/AuthorizeTypes
    class RequirementStatesCountType < BaseObject
      graphql_name 'RequirementStatesCount'
      description 'Counts of requirements by their state'

      field :opened, GraphQL::INT_TYPE, null: true, description: 'Number of opened requirements.'
      field :closed, GraphQL::INT_TYPE, null: true, description: 'Number of closed requirements.'
      # remove this alias in %14.6
      field :archived, GraphQL::INT_TYPE, null: true, description: 'Number of closed requirements.', deprecated: { reason: 'Use `closed`', milestone: '14.0' }

      def archived
        object['closed']
      end
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
