class Projects::ProtectedEnvironmentsController < Projects::ApplicationController
  before_action :authorize_admin_project!
  before_action :protected_environment, except: [:create]

  def create
    protected_environment = ::ProtectedEnvironments::CreateService.new(@project, current_user, protected_environment_params).execute

    if protected_environment.persisted?
      flash[:notice] = s_('ProtectedEnvironment|Your environment has been protected.')
    else
      flash[:alert] = protected_environment.errors.full_messages.join(', ').html_safe
    end

    redirect_to project_settings_ci_cd_path(@project)
  end

  def show
  end

  def update
    @protected_environment = ::ProtectedEnvironments::UpdateService.new(@project, current_user, protected_environment_params).execute(@protected_environment)

    if @protected_environment.valid?
      render json: @protected_environment, status: :ok, include: :deploy_access_levels
    else
      render json: @protected_environment.errors, status: :unprocessable_entity
    end
  end

  def destroy
    ::ProtectedEnvironments::DestroyService.new(@project, current_user).execute(@protected_environment)

    respond_to do |format|
      format.html { redirect_to project_settings_ci_cd_path(@project), status: :found }
      format.js { head :ok }
    end
  end

  private

  def protected_environment
    @protected_environment = @project.protected_environments.find(params[:id])
  end

  def protected_environment_params
    params.require(:protected_environment).permit(:name,
                                                  deploy_access_levels_attributes: deploy_access_level_attributes)
  end

  def deploy_access_level_attributes
    %i(access_level id user_id _destroy group_id)
  end
end
