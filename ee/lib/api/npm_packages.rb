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
        ::Packages::Package.npm.with_name(name).first&.project
      end
    end

    desc 'NPM registry endpoint at instance level' do
      detail 'This feature was introduced in GitLab 11.8'
    end
    params do
      requires :package_name, type: String, desc: 'Package name'
    end
    route_setting :authentication, job_token_allowed: true
    get 'packages/npm/*package_name', format: false, requirements: NPM_ENDPOINT_REQUIREMENTS do
      package_name = params[:package_name]

      project = find_project_by_package_name(package_name)

      authorize_read_package!(project)
      authorize_packages_feature!(project)

      packages = ::Packages::NpmPackagesFinder
        .new(project, package_name).execute

      present NpmPackagePresenter.new(package_name, packages),
        with: EE::API::Entities::NpmPackage
    end

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      before do
        authorize_packages_feature!(user_project)
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
        authorize_read_package!(user_project)

        package = user_project.packages.npm
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
        requires :versions, type: Hash, desc: 'Package version info'
      end
      route_setting :authentication, job_token_allowed: true
      put ':id/packages/npm/:package_name', requirements: NPM_ENDPOINT_REQUIREMENTS do
        authorize_create_package!

        created_package = ::Packages::CreateNpmPackageService
          .new(user_project, current_user, params.merge(build: current_authenticated_job)).execute

        if created_package[:status] == :error
          render_api_error!(created_package[:message], created_package[:http_status])
        else
          created_package
        end
      end
    end
  end
end
