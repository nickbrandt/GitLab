# frozen_string_literal: true

module Packages
  class GroupPackagesFinder
    attr_reader :current_user, :group

    def initialize(current_user, group)
      @current_user = current_user
      @group = group
    end

    def execute
      return ::Packages::Package.none unless group

      packages_for_group_projects
    end

    private

    def packages_for_group_projects
      ::Packages::Package.for_projects(group_projects_visible_to_current_user)
    end

    def group_projects_visible_to_current_user
      ::Project
        .in_namespace(group.self_and_descendants.select(:id))
        .public_or_visible_to_user(current_user, Gitlab::Access::REPORTER)
        .with_project_feature
        .select { |project| Ability.allowed?(current_user, :read_package, project) }
    end
  end
end
