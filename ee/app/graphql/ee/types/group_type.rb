# frozen_string_literal: true

module EE
  module Types
    module GroupType
      extend ActiveSupport::Concern

      prepended do
        %i[epics group_timelogs].each do |feature|
          field "#{feature}_enabled", GraphQL::BOOLEAN_TYPE, null: true, resolve: -> (group, args, ctx) do
            group.feature_available?(feature)
          end, description: "Indicates if #{feature.to_s.humanize} are enabled for namespace"
        end

        field :epic, ::Types::EpicType, null: true,
              description: 'Find a single epic',
              resolver: ::Resolvers::EpicResolver.single

        field :epics, ::Types::EpicType.connection_type, null: true,
              description: 'Find epics',
              max_page_size: 2000,
              resolver: ::Resolvers::EpicResolver

        field :timelogs, ::Types::TimelogType.connection_type, null: false,
              description: 'Time logged in issues by group members',
              complexity: 5,
              resolver: ::Resolvers::TimelogResolver
      end
    end
  end
end
