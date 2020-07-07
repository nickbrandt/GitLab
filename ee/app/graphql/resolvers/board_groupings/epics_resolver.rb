# frozen_string_literal: true

module Resolvers
  module BoardGroupings
    class EpicsResolver < BaseResolver

     type Types::EpicType, null: true

      def resolve(**args)
        board = object.respond_to?(:sync) ? object.sync : object

        return [] unless resolver_object.present?
        return [] unless epic_feature_enabled?

        EpicsFinder.new(context[:current_user], args.merge(board: board)).execute
      end

      private

      attr_reader :resolver_object

      def epic_feature_enabled?
        group.feature_available?(:epics)
      end
    end
  end
end
