# frozen_string_literal: true

class Projects::InsightsController < Projects::ApplicationController
  include InsightsActions

  before_action :authorize_read_project!

  private

  def authorize_read_project!
    render_404 unless can?(current_user, :read_project, project)
  end

  def insights_entity
    project
  end
end
