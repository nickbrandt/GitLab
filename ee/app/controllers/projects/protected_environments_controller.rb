class Projects::ProtectedEnvironmentsController < Projects::ApplicationController

  def create
    protected_environment = ProtectedEnvironments::CreateService.new(@project, current_user, protected_environment_params).execute

    unless protected_environment.persisted?
      flash[:alert] = protected_environment.errors.full_messages.join(', ').html_safe
    end

    redirect_to project_settings_ci_cd_path(@project)
  end

  private

  def protected_environment_params
    params.require(:protected_environment).permit(:name, deploy_access_levels_attributes: [:deploy_access_levels])
  end
end
