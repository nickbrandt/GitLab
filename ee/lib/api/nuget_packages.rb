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
        desc 'The NuGet Package Content endpoint' do
          detail 'This feature was introduced in GitLab 12.6'
        end
        params do
          use :workhorse_upload_params
        end
        put do
          authorize_upload!(authorized_user_project)

          package = ::Packages::Nuget::CreatePackageService.new(authorized_user_project, current_user).execute

          file_params = params.merge(
            file: uploaded_package_file,
            file_name: PACKAGE_FILENAME,
            file_type: PACKAGE_FILETYPE
          )

          track_event('push_package')

          ::Packages::CreatePackageFileService.new(package, file_params).execute

          created!
        rescue ObjectStorage::RemoteStoreError => e
          Gitlab::ErrorTracking.track_exception(e, extra: { file_name: params[:file_name], project_id: authorized_user_project.id })

          forbidden!
        end
        put 'authorize' do
          authorize_workhorse!(authorized_user_project)
        end
      end
    end
  end
end
