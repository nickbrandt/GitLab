# frozen_string_literal: true

module Packages
  class ConanPackageFinder
    attr_reader :query, :current_user

    def initialize(query, current_user)
      @query = query
      @current_user = current_user
    end

    def execute
      packages_for_current_user.with_name_like(query).order_name_asc
    end

    private

    def packages
      Packages::Package.conan
    end

    def packages_for_current_user
      packages.for_projects(projects_visible_to_current_user)
    end

    def projects_visible_to_current_user
      ::Project.public_or_visible_to_user(current_user)
    end
  end
end
