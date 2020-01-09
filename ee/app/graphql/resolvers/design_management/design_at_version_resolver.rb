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

        GitlabSchema.after_lazy(obj) { |dav| inconsistent?(dav) ? nil : dav }
      end

      private

      # If this resolver is mounted on something that has an issue
      # (such as design collection for instance), then we should check
      # that the DesignAtVersion as found by its ID does in fact belong
      # to this issue.
      def inconsistent?(dav)
        return unless dav.present?

        if issue = object&.issue
          dav.design.issue_id != issue.id
        end
      end
    end
  end
end
