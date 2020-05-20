# frozen_string_literal: true
module API
  class GoProxy < Grape::API
    helpers ::API::Helpers::PackagesManagerClientsHelpers
    helpers ::API::Helpers::Packages::BasicAuthHelpers
    helpers ::API::Helpers::Packages::Go::ModuleHelpers

    # basic semver, except case encoded (A => !a)
    MODULE_VERSION_REGEX = /v(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-([-.!a-z0-9]+))?(?:\+([-.!a-z0-9]+))?/.freeze

    MODULE_VERSION_REQUIREMENTS = { module_version: MODULE_VERSION_REGEX }.freeze

    before { require_packages_enabled! }

    helpers do
      # support personal access tokens for HTTP Basic in addition to the usual methods
      def find_personal_access_token
        pa = find_personal_access_token_from_http_basic_auth
        return pa if pa

        # copied from Gitlab::Auth::AuthFinders
        token =
          current_request.params[::Gitlab::Auth::AuthFinders::PRIVATE_TOKEN_PARAM].presence ||
          current_request.env[::Gitlab::Auth::AuthFinders::PRIVATE_TOKEN_HEADER].presence ||
          parsed_oauth_token
        return unless token

        # Expiration, revocation and scopes are verified in `validate_access_token!`
        PersonalAccessToken.find_by_token(token) || raise(::Gitlab::Auth::UnauthorizedError)
      end

      def find_module
        module_name = case_decode params[:module_name]
        bad_request!('Module Name') if module_name.blank?

        mod = ::Packages::Go::ModuleFinder.new(authorized_user_project, module_name).execute

        not_found! unless mod

        mod
      end

      def find_version
        module_version = case_decode params[:module_version]
        ver = ::Packages::Go::VersionFinder.new(find_module).find(module_version)

        not_found! unless ver&.valid?

        ver

      rescue ArgumentError
        not_found!
      end
    end

    params do
      requires :id, type: String, desc: 'The ID of a project'
      requires :module_name, type: String, desc: 'Module name'
    end
    route_setting :authentication, job_token_allowed: true
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      before do
        authorize_read_package!(authorized_user_project)
        authorize_packages_feature!(authorized_user_project)
      end

      namespace ':id/packages/go/*module_name/@v' do
        desc 'Get all tagged versions for a given Go module' do
          detail 'See `go help goproxy`, GET $GOPROXY/<module>/@v/list. This feature was introduced in GitLab 13.1.'
        end
        get 'list' do
          mod = find_module

          content_type 'text/plain'
          mod.versions.map { |t| t.name }.join("\n")
        end

        desc 'Get information about the given module version' do
          detail 'See `go help goproxy`, GET $GOPROXY/<module>/@v/<version>.info. This feature was introduced in GitLab 13.1.'
          success EE::API::Entities::GoModuleVersion
        end
        params do
          requires :module_version, type: String, desc: 'Module version'
        end
        get ':module_version.info', requirements: MODULE_VERSION_REQUIREMENTS do
          ver = find_version

          present ::Packages::Go::ModuleVersionPresenter.new(ver), with: EE::API::Entities::GoModuleVersion
        end

        desc 'Get the module file of the given module version' do
          detail 'See `go help goproxy`, GET $GOPROXY/<module>/@v/<version>.mod. This feature was introduced in GitLab 13.1.'
        end
        params do
          requires :module_version, type: String, desc: 'Module version'
        end
        get ':module_version.mod', requirements: MODULE_VERSION_REQUIREMENTS do
          ver = find_version

          content_type 'text/plain'
          ver.gomod
        end

        desc 'Get a zip of the source of the given module version' do
          detail 'See `go help goproxy`, GET $GOPROXY/<module>/@v/<version>.zip. This feature was introduced in GitLab 13.1.'
        end
        params do
          requires :module_version, type: String, desc: 'Module version'
        end
        get ':module_version.zip', requirements: MODULE_VERSION_REQUIREMENTS do
          ver = find_version

          # TODO: Content-Type should be application/zip, see #214876
          header['Content-Disposition'] = ActionDispatch::Http::ContentDisposition.format(disposition: 'attachment', filename: ver.name + '.zip')
          header['Content-Transfer-Encoding'] = 'binary'
          content_type 'text/plain'
          status :ok
          body ver.archive.string
        end
      end
    end
  end
end
