# frozen_string_literal: true

module Packages
  class ConanPackageFinder
    attr_reader :current_user, :query

    def initialize(current_user, params)
      @current_user = current_user
      @query = params[:query]
    end

    def execute
      packages_for_current_user.with_name_like(query).order_name_asc if query
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
