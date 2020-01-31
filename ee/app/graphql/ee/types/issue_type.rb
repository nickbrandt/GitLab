# frozen_string_literal: true

module EE
  module Types
    module IssueType
      extend ActiveSupport::Concern

      prepended do
        field :epic, ::Types::EpicType, null: true,
              description: 'Epic to which this issue belongs'

        field :weight, GraphQL::INT_TYPE, null: true,
              description: 'Weight of the issue',
              resolve: -> (obj, _args, _ctx) { obj.supports_weight? ? obj.weight : nil }

        field :designs, ::Types::DesignManagement::DesignCollectionType, null: true,
              description: "Deprecated. Use `designCollection`",
              method: :design_collection,
              deprecation_reason: 'Use designCollection'

        field :design_collection, ::Types::DesignManagement::DesignCollectionType, null: true,
              description: 'Collection of design images associated with this issue'
      end
    end
  end
end
