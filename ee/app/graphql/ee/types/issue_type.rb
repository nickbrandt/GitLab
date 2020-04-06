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
              method: :design_collection,
              deprecated: { reason: 'Use `designCollection`', milestone: '12.2' },
              description: 'The designs associated with this issue'

        field :design_collection, ::Types::DesignManagement::DesignCollectionType, null: true,
              description: 'Collection of design images associated with this issue'

        field :health_status,
          ::Types::HealthStatusEnum,
          null: true,
          description: 'Current health status. Returns null if `save_issuable_health_status` feature flag is disabled.',
          resolve: -> (obj, _, _) { obj.supports_health_status? ? obj.health_status : nil }
      end
    end
  end
end
