# frozen_string_literal: true
class Packages::ComposerPackagesFinder
  attr_reader :current_user, :group

  COMPOSER_NAME_MATCH_REGEX = %r{^(.*?)/}.freeze

  def initialize(current_user, group = nil)
    @current_user = current_user
    @group = group
  end

  def execute
    if group
      packages_for_multiple_projects_in_group.find_composer_packages
    else
      packages_for_multiple_projects_matching_namespace
    end
  end

  private

  def packages_for_multiple_projects_matching_namespace
    @packages = []
    projects_visible_to_current_user.each do |project|
      project.packages.find_composer_packages.each do |package|
        package_namespace = package.name.match(COMPOSER_NAME_MATCH_REGEX)[1]

        next unless project.namespace.path == package_namespace

        @packages << package
      end
    end

    @packages
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
end
