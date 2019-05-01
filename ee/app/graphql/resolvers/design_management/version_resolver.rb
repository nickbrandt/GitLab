# frozen_string_literal: true

module Resolvers
  module DesignManagement
    class VersionResolver < BaseResolver
      type Types::DesignManagement::VersionType.connection_type, null: false

      alias_method :design_or_collection, :object

      def resolve(*_args)
        unless Ability.allowed?(context[:current_user], :read_design, design_or_collection)
          return ::DesignManagement::Version.none
        end

        design_or_collection.versions.ordered
      end
    end
  end
end
