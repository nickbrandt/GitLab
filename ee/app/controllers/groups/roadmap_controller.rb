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
  end
end
