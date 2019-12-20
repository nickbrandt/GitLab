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

    default_format :json

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
          return unauthorized_project_message
        end

        project
      end

      def unauthorized_project_message
        current_user ? not_found! : unauthorized_with_header!
      end

      def unauthorized_with_header!
        header(AUTHENTICATE_REALM_HEADER, AUTHENTICATE_REALM_NAME)
        unauthorized!
      end
    end

    before do
      require_packages_enabled!
      authenticate_non_get!
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
      end
    end
  end
end
