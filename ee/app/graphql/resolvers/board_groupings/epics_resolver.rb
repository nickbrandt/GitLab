# frozen_string_literal: true

module Resolvers
  module BoardGroupings
    class EpicsResolver < BaseResolver

      type Types::EpicType, null: true

      def resolve(**args)
        @board = object.respond_to?(:sync) ? object.sync : object

        return Epic.none unless board.present?
        return Epic.none unless epic_feature_enabled?

        list_service = Boards::Issues::ListService.new(board.resource_parent, current_user, { all: true, board_id: board.id })

        # get bare issues by removing ordering, grouping and extra selected fields to get just the issues filtered by board scope.
        issues = list_service.execute.except(:order).except(:group).except(:select).distinct

        # Depending on which level the board is, user can see epics related to issues from various groups in the hierarchy,
        # so we need to look-up epics from all groups in the hierarchy.
        board_params = { group_id: group.id, include_ancestor_groups: true, include_descendant_groups: true, issues: issues }
        EpicsFinder.new(context[:current_user], args.merge(board_params)).execute.limit(10)
      end

      private

      attr_accessor :board

      def group
        board.project_board? ? board.project.group : board.group
      end

      def epic_feature_enabled?
        group.feature_available?(:epics)
      end
    end
  end
end
