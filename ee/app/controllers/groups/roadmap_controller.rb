# frozen_string_literal: true

module Groups
  class RoadmapController < Groups::ApplicationController
    include IssuableCollections
    include EpicsActions

    before_action :check_epics_available!
    before_action :group
    before_action :persist_roadmap_layout, only: [:show]

    # show roadmap for a group
    def show
      # Used to persist the order and show the correct sorting dropdown on UI.
      @sort = set_sort_order
      @epics_state = epics_state_in_user_preference || 'all'
      @epics_count = EpicsFinder.new(current_user, group_id: @group.id).execute.count
    end

    private

    def issuable_sorting_field
      :epics_sort
    end

    def persist_roadmap_layout
      return unless current_user

      roadmap_layout = params[:layout]&.downcase

      return unless User.roadmap_layouts[roadmap_layout]
      return if current_user.roadmap_layout == roadmap_layout

      Users::UpdateService.new(current_user, user: current_user, roadmap_layout: roadmap_layout).execute
    end

    def epics_state_in_user_preference
      return unless current_user

      preference = current_user.user_preference
      state_id = Epic.states[params[:state]]

      if params[:state].present? && state_id != preference.roadmap_epics_state
        preference.update(roadmap_epics_state: state_id)
      end

      Epic.states.key(preference.roadmap_epics_state)
    end
  end
end
