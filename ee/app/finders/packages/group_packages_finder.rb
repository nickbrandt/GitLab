# frozen_string_literal: true

module Packages
  class GroupPackagesFinder
    attr_reader :current_user, :group, :params

    def initialize(current_user, group, params = { exclude_subgroups: false })
      @current_user = current_user
      @group = group
      @params = params
    end

    def execute
      return ::Packages::Package.none unless group

      packages_for_group_projects
    end

    private

    def packages_for_group_projects
      packages = ::Packages::Package.for_projects(group_projects_visible_to_current_user)

      return packages unless package_type

      packages.with_package_type(package_type)
    end

    def group_projects_visible_to_current_user
      ::Project
        .in_namespace(groups)
        .public_or_visible_to_user(current_user, Gitlab::Access::REPORTER)
        .with_project_feature
        .select { |project| Ability.allowed?(current_user, :read_package, project) }
    end

    def package_type
      @params[:package_type].presence
    end

    def groups
      return [group] if exclude_subgroups?

      group.self_and_descendants
    end

    def exclude_subgroups?
      params[:exclude_subgroups]
    end
  end
end
