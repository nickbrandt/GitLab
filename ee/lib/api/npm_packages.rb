# frozen_string_literal: true
module API
  class NpmPackages < Grape::API
    NPM_ENDPOINT_REQUIREMENTS = {
      package_name: API::NO_SLASH_URL_PART_REGEX
    }.freeze

    rescue_from ActiveRecord::RecordInvalid do |e|
      render_api_error!(e.message, 400)
    end

    before do
      require_packages_enabled!
      authenticate_non_get!
    end

    helpers ::API::Helpers::PackagesHelpers

    helpers do
      def find_project_by_package_name(name)
        Project.find_by_full_path(name.sub('@', ''))
      end
    end

    desc 'NPM registry endpoint at instance level' do
      detail 'This feature was introduced in GitLab 11.8'
    end
    params do
      requires :package_name, type: String, desc: 'Package name'
    end
    route_setting :authentication, job_token_allowed: true
    get 'packages/npm/*package_name', requirements: NPM_ENDPOINT_REQUIREMENTS do
      package_name = params[:package_name]

      # To avoid name collision we require project path and project package be the same.
      # For packages that have different name from the project we should use
      # the endpoint that includes project id
      project = find_project_by_package_name(package_name)

      authorize!(:read_package, project)
      forbidden! unless project.feature_available?(:packages)

      packages = project.packages.with_name(package_name)

      present NpmPackagePresenter.new(project, package_name, packages),
        with: EE::API::Entities::NpmPackage
    end

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      before do
        authorize_packages_feature!
      end

      desc 'Download the NPM tarball' do
        detail 'This feature was introduced in GitLab 11.8'
      end
      params do
        requires :package_name, type: String, desc: 'Package name'
        requires :file_name, type: String, desc: 'Package file name'
      end
      route_setting :authentication, job_token_allowed: true
      get ':id/packages/npm/*package_name/-/*file_name', format: false do
        authorize_download_package!

        package = user_project.packages
          .by_name_and_file_name(params[:package_name], params[:file_name])

        package_file = ::Packages::PackageFileFinder
          .new(package, params[:file_name]).execute!

        present_carrierwave_file!(package_file.file)
      end

      desc 'Create NPM package' do
        detail 'This feature was introduced in GitLab 11.8'
      end
      params do
        requires :package_name, type: String, desc: 'Package name'
      end
      route_setting :authentication, job_token_allowed: true
      put ':id/packages/npm/:package_name', requirements: NPM_ENDPOINT_REQUIREMENTS do
        authorize_create_package!

        created_package = ::Packages::CreateNpmPackageService
          .new(user_project, current_user, params).execute

        if created_package[:status] == :error
          render_api_error!(created_package[:message], created_package[:http_status])
        else
          created_package
        end
      end
    end
  end
end
