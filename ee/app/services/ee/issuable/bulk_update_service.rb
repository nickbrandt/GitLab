# frozen_string_literal: true

module EE
  module Issuable
    module BulkUpdateService
      extend ::Gitlab::Utils::Override

      private

      override :find_issuables
      def find_issuables(parent, model_class, ids)
        return model_class.for_ids(ids).in_selected_groups(parent.self_and_descendants) if model_class == ::Epic

        super
      end

      override :permitted_attrs
      def permitted_attrs(type)
        return super unless type == 'issue'

        super.push(:health_status, :epic_id)
      end

      override :set_update_params
      def set_update_params(type)
        super

        set_health_status
        set_epic_param

        params
      end

      def set_health_status
        return unless params[:health_status].present?

        params[:health_status] = nil if params[:health_status] == IssuableFinder::Params::NONE.to_s
      end

      def set_epic_param
        return unless params[:epic_id].present?

        epic_id = params.delete(:epic_id)
        epic = find_epic(epic_id)

        # Set as nil if removing an epic or set as the Epic object
        # if epic_id is present and the Epic was found.
        params[:epic] = epic if epic.nil? || epic.present?
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def find_epic(epic_id)
        return if remove_epic?(epic_id)

        group = parent.is_a?(Group) ? parent : parent.group
        return unless group.present?

        EpicsFinder.new(current_user, group_id: group.id,
                        include_ancestor_groups: true).find(epic_id)
      rescue ActiveRecord::RecordNotFound
        false
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def remove_epic?(epic_id)
        epic_id == IssuableFinder::Params::NONE.to_s
      end
    end
  end
end
