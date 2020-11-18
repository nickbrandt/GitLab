# frozen_string_literal: true

class Projects::RequirementsManagement::RequirementsController < Projects::ApplicationController
  before_action :authorize_read_requirement!
  before_action :authorize_import_access!, only: [:import_csv]
  before_action do
    push_frontend_feature_flag(:import_requirements_csv, project)
  end

  feature_category :requirements_management

  def index
    respond_to do |format|
      format.html
    end
  end

  def import_csv
    if uploader = UploadService.new(project, params[:file]).execute
      RequirementsManagement::ImportRequirementsCsvWorker.perform_async(current_user.id, project.id, uploader.upload.id) # rubocop:disable CodeReuse/Worker

      flash[:notice] = _("Your requirements are being imported. Once finished, you'll get a confirmation email.")
    else
      flash[:alert] = _("File upload error.")
    end

    redirect_to project_requirements_management_requirements_path(project)
  end

  def authorize_import_access!
    ensure_import_enabled

    return if can?(current_user, :import_requirements, project)
  end

  def ensure_import_enabled
    render_404 unless Feature.enabled?(:import_requirements_csv, project, default_enabled: false)
  end
end
