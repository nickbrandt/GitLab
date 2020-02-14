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

      def find_packages
        packages = package_finder.execute

        not_found!('Packages') unless packages.exists?

        packages
      end

      def find_package
        package = package_finder(package_version: params[:package_version]).execute
                                                                           .first

        not_found!('Package') unless package

        package
      end

      def package_finder(finder_params = {})
        ::Packages::Nuget::PackageFinder.new(
          authorized_user_project,
          finder_params.merge(package_name: params[:package_name])
        )
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
        not_found! if Feature.disabled?(:nuget_package_registry, authorized_user_project, default_enabled: true)
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
            file_name: PACKAGE_FILENAME
          )

          package = ::Packages::Nuget::CreatePackageService.new(authorized_user_project, current_user)
                                                           .execute

          package_file = ::Packages::CreatePackageFileService.new(package, file_params)
                                                             .execute

          track_event('push_package')

          ::Packages::Nuget::ExtractionWorker.perform_async(package_file.id) # rubocop:disable CodeReuse/Worker

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
            present ::Packages::Nuget::PackagesMetadataPresenter.new(find_packages),
                    with: EE::API::Entities::Nuget::PackagesMetadata
          end

          desc 'The NuGet Metadata Service - Package name and version level' do
            detail 'This feature was introduced in GitLab 12.8'
          end
          params do
            requires :package_version, type: String, desc: 'The NuGet package version', regexp: API::NO_SLASH_URL_PART_REGEX
          end
          get '*package_version', format: :json do
            present ::Packages::Nuget::PackageMetadataPresenter.new(find_package),
                    with: EE::API::Entities::Nuget::PackageMetadata
          end
        end

        # https://docs.microsoft.com/en-us/nuget/api/package-base-address-resource
        params do
          requires :package_name, type: String, desc: 'The NuGet package name', regexp: API::NO_SLASH_URL_PART_REGEX
        end
        namespace '/download/*package_name' do
          before do
            authorize_read_package!(authorized_user_project)
          end

          desc 'The NuGet Content Service - index request' do
            detail 'This feature was introduced in GitLab 12.8'
          end
          get 'index', format: :json do
            present ::Packages::Nuget::PackagesVersionsPresenter.new(find_packages),
                    with: EE::API::Entities::Nuget::PackagesVersions
          end

          desc 'The NuGet Content Service - content request' do
            detail 'This feature was introduced in GitLab 12.8'
          end
          params do
            requires :package_version, type: String, desc: 'The NuGet package version', regexp: API::NO_SLASH_URL_PART_REGEX
            requires :package_filename, type: String, desc: 'The NuGet package filename', regexp: API::NO_SLASH_URL_PART_REGEX
          end
          get '*package_version/*package_filename', format: :nupkg do
            filename = "#{params[:package_filename]}.#{params[:format]}"
            package_file = ::Packages::PackageFileFinder.new(find_package, filename, with_file_name_like: true)
                                                        .execute

            not_found!('Package') unless package_file

            # nuget and dotnet don't support 302 Moved status codes, supports_direct_download has to be set to false
            present_carrierwave_file!(package_file.file, supports_direct_download: false)
          end
        end
      end
    end
  end
end
