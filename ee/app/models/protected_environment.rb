class ProtectedEnvironment < ActiveRecord::Base
  include ProtectedRef
  prepend EE::ProtectedRef

  protected_ref_access_levels :deploy

  belongs_to :project

  validates :name, presence: true
  validates :project, presence: true

  def self.protected?(project, environment_name)
    names = project.protected_environments.select(:name)

    matching(environment_name, protected_refs: names).present?
  end
end
