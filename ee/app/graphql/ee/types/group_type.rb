# frozen_string_literal: true

module EE
  module Types
    module GroupType
      extend ActiveSupport::Concern

      prepended do
        %i[epics].each do |feature|
          field "#{feature}_enabled", GraphQL::BOOLEAN_TYPE, null: true, resolve: -> (group, args, ctx) do
            group.feature_available?(feature)
          end
        end

        field :epic,
              ::Types::EpicType,
              null: true,
              resolver: ::Resolvers::EpicResolver.single

        field :epics,
              ::Types::EpicType.connection_type,
              null: true,
              resolver: ::Resolvers::EpicResolver
      end
    end
  end
end
