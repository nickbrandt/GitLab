# frozen_string_literal: true

module Resolvers
  module DesignManagement
    class VersionResolver < BaseResolver
      type Types::DesignManagement::VersionType.connection_type, null: false

      alias_method :design_or_collection, :object

      def resolve(parent: nil)
        # Find an `at_version` argument passed to a parent node.
        #
        # If one is found, then a design collection further up the AST
        # has been filtered to reflect designs at that version, and so
        # for consistency we should only present versions up to the given
        # version here.
        at_version = Gitlab::Graphql::FindArgumentInParent.find(parent, :at_version, limit_depth: 4)
        version = at_version ? GitlabSchema.object_from_id(at_version) : nil

        ::DesignManagement::VersionsFinder.new(
          design_or_collection,
          context[:current_user],
          earlier_or_equal_to: version
        ).execute
      end
    end
  end
end
