# frozen_string_literal: true

module Resolvers
  module DesignManagement
    class DesignAtVersionResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      type Types::DesignManagement::DesignAtVersionType, null: false

      authorize :read_design

      argument :id, GraphQL::ID_TYPE,
               required: true,
               description: 'The Global ID of the design at this version'

      alias_method :resolve, :authorized_find!

      def find_object(id:)
        obj = GitlabSchema.object_from_id(id, expected_type: ::DesignManagement::DesignAtVersion)

        inconsistent?(obj) ? nil : obj
      end

      def current_user
        context[:current_user]
      end

      private

      def inconsistent?(dav)
        return unless dav.present?

        if issue = object.try(:issue)
          dav.design.issue_id != issue.id
        end
      end
    end
  end
end
