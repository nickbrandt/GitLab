# frozen_string_literal: true

class Projects::InsightsController < Projects::ApplicationController
  include InsightsActions

  helper_method :project_insights_config

  before_action :authorize_read_project!

  private

  def authorize_read_project!
    render_404 unless can?(current_user, :read_project, project)
  end

  def insights_entity
    project
  end

  def config_data
    project_insights_config.filtered_config
  end

  def project_insights_config
    @project_insights_config ||= Gitlab::Insights::ProjectInsightsConfig.new(project: project, insights_config: insights_entity.insights_config)
  end
end
