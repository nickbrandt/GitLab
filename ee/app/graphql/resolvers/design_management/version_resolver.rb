# frozen_string_literal: true

module Resolvers
  module DesignManagement
    class VersionResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      type Types::DesignManagement::VersionType, null: true

      authorize :read_design

      argument :id, GraphQL::ID_TYPE,
               required: true,
               description: 'The Global ID of the version'

      alias_method :resolve, :authorized_find!

      def find_object(id:)
        GitlabSchema.object_from_id(id, expected_type: ::DesignManagement::Version)
      end
    end
  end
end
