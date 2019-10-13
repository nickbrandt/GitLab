# frozen_string_literal: true

module EE
  module Types
    module IssueType
      extend ActiveSupport::Concern

      prepended do
        field :epic, ::Types::EpicType, null: true, description: 'The epic to which issue belongs'

        field :weight, GraphQL::INT_TYPE, # rubocop:disable Graphql/Descriptions
              null: true,
              resolve: -> (obj, _args, _ctx) { obj.supports_weight? ? obj.weight : nil }

        field :designs, ::Types::DesignManagement::DesignCollectionType, # rubocop:disable Graphql/Descriptions
              null: true, method: :design_collection,
              deprecation_reason: 'use design_collection'

        field :design_collection, ::Types::DesignManagement::DesignCollectionType, null: true # rubocop:disable Graphql/Descriptions
      end
    end
  end
end
