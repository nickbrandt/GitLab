class ProtectedEnvironment::DeployAccessLevel < ActiveRecord::Base
  ALLOWED_ACCESS_LEVELS = [
    Gitlab::Access::MAINTAINER,
    Gitlab::Access::DEVELOPER,
    Gitlab::Access::NO_ACCESS,
    Gitlab::Access::ADMIN
  ].freeze

  HUMAN_ACCESS_LEVELS = {
    Gitlab::Access::MAINTAINER => 'Maintainers'.freeze,
    Gitlab::Access::DEVELOPER => 'Developers + Maintainers'.freeze,
    Gitlab::Access::NO_ACCESS => 'No one'.freeze
  }.freeze

  belongs_to :user
  belongs_to :group
  belongs_to :protected_environment

  validates :access_level, presence: true, if: :role?, inclusion: {
    in: ALLOWED_ACCESS_LEVELS
  }
  validates :group_id, uniqueness: { scope: :protected_environment, allow_nil: true }
  validates :user_id, uniqueness: { scope: :protected_environment, allow_nil: true }
  validates :access_level, uniqueness: { scope: :protected_environment, if: :role?,
                                         conditions: -> { where(user_id: nil, group_id: nil) } }

  scope :by_user, -> (user) { where(user: user ) }
  scope :by_group, -> (group) { where(group: group ) }
  scope :for_role, -> { where(user: nil, group: nil) }
  scope :for_user, -> { where.not(user: nil) }
  scope :for_group, -> { where.not(group: nil) }

  delegate :project, to: :protected_environment

  def check_access(user)
    return true if user.admin?
    return user.id == user_id if self.user.present?
    return group.users.exists?(user.id) if group.present?

    project.team.max_member_access(user.id) >= access_level
  end

  def type
    if user.present?
      :user
    elsif group.present?
      :group
    else
      :role
    end
  end

  def role?
    type == :role
  end

  def humanize
    return user.name if user.present?
    return group.name if group.present?

    HUMAN_ACCESS_LEVELS[access_level]
  end
end
