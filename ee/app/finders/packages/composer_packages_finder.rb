# frozen_string_literal: true
class Packages::ComposerPackagesFinder
  attr_reader :current_user, :group

  COMPOSER_NAME_MATCH_REGEX = %r{^(.*?)/}

  def initialize(current_user, group = nil)
    @current_user = current_user
    @group = group
  end

  def execute
    if group
      packages_for_multiple_projects_in_group.find_composer_packages
    else
      packages_for_multiple_projects.find_composer_packages
    end
  end

  private

  def packages_for_multiple_projects
    ::Packages::Package.for_projects(version_match_namespace(projects_visible_to_current_user))
  end

  def projects_visible_to_current_user
    ::Project.public_or_visible_to_user(current_user)
  end

  def packages_for_multiple_projects_in_group
    ::Packages::Package.for_projects(projects_visible_in_group_to_current_user(group, current_user))
  end

  def projects_visible_in_group_to_current_user(group, user = nil)
    ::Project.in_namespace(group.self_and_descendants.select(:id)).public_or_visible_to_user(user)
  end

  def version_match_namespace(projects)
    projects.each do |project|
      next unless project.packages.first

      match = project.packages.first.name.match(COMPOSER_NAME_MATCH_REGEX)
      match.present? && project.namespace.name == match[1]
    end
  end
end
