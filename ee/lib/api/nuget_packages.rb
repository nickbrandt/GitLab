# frozen_string_literal: true

# NuGet Package Manager Client API
#
# These API endpoints are not meant to be consumed directly by users. They are
# called by the NuGet package manager client when users run commands
# like `nuget install` or `nuget push`.
module API
  class NugetPackages < Grape::API
    helpers ::API::Helpers::PackagesManagerClientsHelpers

    AUTHORIZATION_HEADER = 'Authorization'
    AUTHENTICATE_REALM_HEADER = 'Www-Authenticate: Basic realm'
    AUTHENTICATE_REALM_NAME = 'GitLab Nuget Package Registry'
    POSITIVE_INTEGER_REGEX = %r{\A[1-9]\d*\z}.freeze

    PACKAGE_FILENAME = 'package.nupkg'
    PACKAGE_FILETYPE = 'application/octet-stream'

    default_format :json

    rescue_from ArgumentError do |e|
      render_api_error!(e.message, 400)
    end

    helpers do
      def find_personal_access_token
        find_personal_access_token_from_http_basic_auth
      end

      def authorized_user_project
        @authorized_user_project ||= authorized_project_find!(params[:id])
      end

      def authorized_project_find!(id)
        project = find_project(id)

        unless project && can?(current_user, :read_project, project)
          return unauthorized_or! { not_found! }
        end

        project
      end

      def authorize!(action, subject = :global, reason = nil)
        return if can?(current_user, action, subject)

        unauthorized_or! { forbidden!(reason) }
      end

      def unauthorized_or!
        current_user ? yield : unauthorized_with_header!
      end

      def unauthorized_with_header!
        header(AUTHENTICATE_REALM_HEADER, AUTHENTICATE_REALM_NAME)
        unauthorized!
      end
    end

    before do
      require_packages_enabled!
    end

    params do
      requires :id, type: String, desc: 'The ID of a project', regexp: POSITIVE_INTEGER_REGEX
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      before do
        not_found! if Feature.disabled?(:nuget_package_registry, authorized_user_project)
        authorize_packages_feature!(authorized_user_project)
      end

      namespace ':id/packages/nuget' do
        # https://docs.microsoft.com/en-us/nuget/api/service-index
        desc 'The NuGet Service Index' do
          detail 'This feature was introduced in GitLab 12.6'
        end
        get 'index', format: :json do
          authorize_read_package!(authorized_user_project)

          present ::Packages::Nuget::ServiceIndexPresenter.new(authorized_user_project),
            with: EE::API::Entities::Nuget::ServiceIndex
        end

        # https://docs.microsoft.com/en-us/nuget/api/package-publish-resource
        desc 'The NuGet Package Publish endpoint' do
          detail 'This feature was introduced in GitLab 12.6'
        end
        params do
          use :workhorse_upload_params
        end
        put do
          authorize_upload!(authorized_user_project)

          file_params = params.merge(
            file: uploaded_package_file(:package),
            file_name: PACKAGE_FILENAME,
            file_type: PACKAGE_FILETYPE
          )

          package = ::Packages::Nuget::CreatePackageService.new(authorized_user_project, current_user)
                                                           .execute

          package_file = ::Packages::CreatePackageFileService.new(package, file_params)
                                                             .execute

          track_event('push_package')

          ::Packages::Nuget::ExtractionWorker.perform_async(package_file.id)

          created!
        rescue ObjectStorage::RemoteStoreError => e
          Gitlab::ErrorTracking.track_exception(e, extra: { file_name: params[:file_name], project_id: authorized_user_project.id })

          forbidden!
        end
        put 'authorize' do
          authorize_workhorse!(subject: authorized_user_project, has_length: false)
        end

        params do
          requires :package_name, type: String, desc: 'The NuGet package name', regexp: API::NO_SLASH_URL_PART_REGEX
        end
        namespace '/metadata/*package_name' do
          before do
            authorize_read_package!(authorized_user_project)
          end

          # https://docs.microsoft.com/en-us/nuget/api/registration-base-url-resource
          desc 'The NuGet Metadata Service - Package name level' do
            detail 'This feature was introduced in GitLab 12.8'
          end
          get 'index', format: :json do
            packages = ::Packages::Nuget::PackageFinder.new(authorized_user_project, package_name: params[:package_name])
                                                       .execute

            not_found!('Packages') unless packages.exists?

            present ::Packages::Nuget::PackagesMetadataPresenter.new(packages),
                    with: EE::API::Entities::Nuget::PackagesMetadata
          end

          desc 'The NuGet Metadata Service - Package name and version level' do
            detail 'This feature was introduced in GitLab 12.8'
          end
          params do
            requires :package_version, type: String, desc: 'The NuGet package version', regexp: API::NO_SLASH_URL_PART_REGEX
          end
          get '*package_version', format: :json do
            package = ::Packages::Nuget::PackageFinder
              .new(authorized_user_project, package_name: params[:package_name], package_version: params[:package_version])
              .execute
              .first

            not_found!('Package') unless package

            present ::Packages::Nuget::PackageMetadataPresenter.new(package),
                    with: EE::API::Entities::Nuget::PackageMetadata
          end
        end

        # https://docs.microsoft.com/en-us/nuget/api/package-base-address-resource
        desc 'The NuGet Content Service' do
          detail 'This feature was introduced in GitLab 12.8'
        end
        params do
          requires :package_name, type: String, desc: 'The NuGet package name', regexp: API::NO_SLASH_URL_PART_REGEX
          requires :package_version, type: String, desc: 'The NuGet package version', regexp: API::NO_SLASH_URL_PART_REGEX
        end
        namespace '/download/*package_name/*package_version' do
          params do
            requires :package_filename, type: String, desc: 'The NuGet package filename', regexp: API::NO_SLASH_URL_PART_REGEX
          end
          get '*package_filename' do
            not_found!('package not found') # TODO NUGET API: not implemented yet.
          end
        end
      end
    end
  end
end
