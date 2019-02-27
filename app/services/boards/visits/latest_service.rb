# frozen_string_literal: true

module Boards
  module Visits
    class LatestService < Boards::BaseService
      def execute
        return nil unless current_user

        relation = recent_visit_model

        if params[:count] && params[:count] > 1
          relation = relation.preload(:board)
        end

        relation.latest(current_user, parent, params[:count])
      end

      private

      def recent_visit_model
        parent.is_a?(Group) ? BoardGroupRecentVisit : BoardProjectRecentVisit
      end
    end
  end
end
