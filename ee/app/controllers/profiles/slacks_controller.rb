# frozen_string_literal: true

class Profiles::SlacksController < Profiles::ApplicationController
  include IntegrationsHelper

  skip_before_action :authenticate_user!

  layout 'application'

  feature_category :users

  def edit
    @projects = disabled_projects.select([:id, :name]) if current_user
  end

  def slack_link
    project = disabled_projects.find(params[:project_id])
    link = add_to_slack_link(project, Gitlab::CurrentSettings.slack_app_id)

    render json: { add_to_slack_link: link }
  end

  private

  def disabled_projects
    @disabled_projects ||= current_user
      .authorized_projects(Gitlab::Access::MAINTAINER)
      .with_slack_application_disabled
  end
end
