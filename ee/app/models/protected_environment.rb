class ProtectedEnvironment < ActiveRecord::Base
  belongs_to :project
  has_many :deploy_access_levels, inverse_of: :protected_environment

  accepts_nested_attributes_for :deploy_access_levels, allow_destroy: true

  validates :deploy_access_levels, length: { is: 1 }, if: -> { false }
  validates :name, :project, presence: true

  scope :deploy_access_by_user, -> (user) {
    DeployAccessLevel
      .joins(:protected_environment)
      .where(protected_environment_id: self.ids)
      .merge(DeployAccessLevel.by_user(user))
  }

  scope :deploy_access_by_group, -> (group) {
    DeployAccessLevel
      .joins(:protected_environment)
      .where(protected_environment_id: self.ids)
      .merge(DeployAccessLelve.by_group(group))
  }

  def self.protected?(project, environment_name)
    project.protected_environments.exists?(name: environment_name)
  end
end
