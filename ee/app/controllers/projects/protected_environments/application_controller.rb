class Projects::ProtectedEnvironments::ApplicationController < Projects::ApplicationController
  protected

  def load_protected_environment
    @protected_environment = @project.protected_environmentes.find(params[:protected_environment_id])
  end
end
