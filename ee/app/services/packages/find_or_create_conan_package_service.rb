# frozen_string_literal: true
module Packages
  class FindOrCreateConanPackageService < BaseService
    def execute
      package = ::Packages::ConanPackageFinder
        .new(params[:recipe], current_user, project: project).execute

      unless package
        package_params = {
          name: params[:recipe],
          path: params[:path],
          version: params[:url_recipe].split('/')[1]
        }

        package = ::Packages::CreateConanPackageService
          .new(project, current_user, package_params).execute
      end

      package
    end
  end
end
