# frozen_string_literal: true

class Projects::ServiceDeskController < Projects::ApplicationController
  before_action :authorize_admin_project!

  def show
    json_response
  end

  def update
    Projects::UpdateService.new(project, current_user, { service_desk_enabled: params[:service_desk_enabled] }).execute

    ServiceDeskSetting.update_template_key_for(project: project, issue_template_key: params[:issue_template_key])

    json_response
  end

  private

  def json_response
    respond_to do |format|
      service_desk_settings = project.service_desk_setting

      service_desk_attributes =
        {
          service_desk_address: project.service_desk_address,
          service_desk_enabled: project.service_desk_enabled,
          issue_template_key: service_desk_settings&.issue_template_key,
          template_file_missing: service_desk_settings&.issue_template_missing?
        }

      format.json { render json: service_desk_attributes }
    end
  end
end
