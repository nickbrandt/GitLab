# frozen_string_literal: true

module API
  class ProjectPackages < Grape::API
    include PaginationParams

    before do
      authorize_packages_access!(user_project)
    end

    helpers ::API::Helpers::PackagesHelpers

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Get all project packages' do
        detail 'This feature was introduced in GitLab 11.8'
        success EE::API::Entities::Package
      end
      params do
        use :pagination
      end
      get ':id/packages' do
        packages = user_project.packages

        present paginate(packages), with: EE::API::Entities::Package, user: current_user
      end

      desc 'Get a single project package' do
        detail 'This feature was introduced in GitLab 11.9'
        success EE::API::Entities::Package
      end
      params do
        requires :package_id, type: Integer, desc: 'The ID of a package'
      end
      get ':id/packages/:package_id' do
        package = ::Packages::PackageFinder
          .new(user_project, params[:package_id]).execute

        present package, with: EE::API::Entities::Package, user: current_user
      end

      desc 'Remove a package' do
        detail 'This feature was introduced in GitLab 11.9'
      end
      params do
        requires :package_id, type: Integer, desc: 'The ID of a package'
      end
      delete ':id/packages/:package_id' do
        authorize_destroy_package!

        package = ::Packages::PackageFinder
          .new(user_project, params[:package_id]).execute

        destroy_conditionally!(package)
      end
    end
  end
end
