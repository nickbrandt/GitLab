class ProtectedEnvironment::DeployAccessLevel < ActiveRecord::Base
  belongs_to :protected_environment
  belongs_to :user
  belongs_to :group

  delegate :project, to: :protected_environment

  def check_access(user)
    return true if user.admin?
    return user.id == user_id if self.user.present?
    return group.users.exists?(user.id) if group.present?

    project.team.max_member_access(user.id) >= access_level
  end
end
