# frozen_string_literal: true

module Resolvers
  module Users
    class ManageableGroupsResolver < BaseResolver
      type Types::GroupType.connection_type, null: true

      argument :search, GraphQL::STRING_TYPE, required: false, description: 'Search by group name or path.'

      alias_method :user, :object

      def resolve(**args)
        manageable_groups = user.manageable_groups(include_groups_with_developer_maintainer_access: true)

        return manageable_groups.search(args[:search]) if args[:search].present?

        manageable_groups
      end
    end
  end
end
