# frozen_string_literal: true

module RoadmapsHelper
  def roadmap_layout
    (current_user&.roadmap_layout || params[:layout].presence || EE::User::DEFAULT_ROADMAP_LAYOUT).upcase
  end

  def roadmap_sort_order
    current_user&.user_preference&.roadmaps_sort || sort_value_start_date_soon
  end
end
