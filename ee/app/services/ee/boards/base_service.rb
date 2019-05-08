# frozen_string_literal: true

module EE
  module Boards
    module BaseService
      # rubocop: disable CodeReuse/ActiveRecord
      def set_assignee
        return unless params.key?(:assignee_id)

        assignee = ::User.find_by(id: params.delete(:assignee_id))
        params.merge!(assignee: assignee)
      end
      # rubocop: enable CodeReuse/ActiveRecord

      # rubocop: disable CodeReuse/ActiveRecord
      def set_milestone
        return unless params.key?(:milestone_id)

        milestone_id = params[:milestone_id]

        return if [::Milestone::None.id,
                   ::Milestone::Upcoming.id,
                   ::Milestone::Started.id].include?(milestone_id)

        finder_params =
          case parent
          when Group
            { group_ids: [parent.id] }
          when Project
            { project_ids: [parent.id], group_ids: [parent.group&.id] }
          end

        milestone = ::MilestonesFinder.new(finder_params).find_by(id: milestone_id)

        params[:milestone_id] = milestone&.id
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def set_labels
        if params.key?(:label_ids)
          params[:label_ids] = (labels_service.filter_labels_ids_in_param(:label_ids) || [])
        elsif params.key?(:labels)
          params[:label_ids] = (labels_service.find_or_create_by_titles.map(&:id) || [])
        end
      end

      def labels_service
        @labels_service ||= ::Labels::AvailableLabelsService.new(current_user, parent, params)
      end
    end
  end
end
