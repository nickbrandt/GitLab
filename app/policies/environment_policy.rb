class EnvironmentPolicy < BasePolicy
  delegate { @subject.project }

  condition(:stop_with_deployment_allowed) do
    @subject.stop_action? && can?(:create_deployment) && can?(:update_build, @subject.stop_action)
  end

  condition(:stop_with_update_allowed) do
    !@subject.stop_action? && can?(:update_environment, @subject)
  end

  condition(:protected_environment) { protected_environment? }

  condition(:deployable_by_user) { deployable_by_user? }

  condition(:maintainer_or_admin) { maintainer_or_admin? }

  condition(:admin) { admin? }

  rule { stop_with_deployment_allowed | stop_with_update_allowed }.enable :stop_environment

  rule { (protected_environment & ~deployable_by_user) | ~maintainer_or_admin }.policy do
    prevent :stop_environment
  end

  private

  def deployable_by_user?
    @subject.protected_deployable_by_user(@user)
  end

  def protected_environment?
    @subject.protected?
  end

  def maintainer_or_admin?
    maintainer? || admin?
  end

  def maintainer?
    access_level >= ::Gitlab::Access::MAINTAINER
  end

  def admin?
    @user.admin?
  end

  def access_level
    return -1 if @user.nil?

    @subject.project.team.max_member_access(@user.id)
  end
end
