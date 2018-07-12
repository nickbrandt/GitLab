class Projects::ProtectedEnvironmentsController < Projects::ApplicationController
  before_action :authorize_admin_project!

  def create
    protected_environment = ::ProtectedEnvironments::CreateService.new(@project, current_user, protected_environment_params).execute

    if protected_environment.persisted?
      flash[:notice] = s_('ProtectedEnvironment|Your environment has been protected.')
    else
      flash[:alert] = protected_environment.errors.full_messages.join(', ').html_safe
    end

    redirect_to project_settings_ci_cd_path(@project)
  end

  private

  def protected_environment_params
    params.require(:protected_environment).permit(:name, deploy_access_levels_attributes: [:access_level, :user_id, :group_id])
  end
end
