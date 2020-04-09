# frozen_string_literal: true
module API
  class GoProxy < Grape::API
    helpers ::API::Helpers::PackagesHelpers
    helpers ::API::Helpers::Packages::Go::ModuleHelpers

    # basic semver, except case encoded (A => !a)
    MODULE_VERSION_REGEX = /v(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-([-.!a-z0-9]+))?(?:\+([-.!a-z0-9]+))?/.freeze

    MODULE_VERSION_REQUIREMENTS = { module_version: MODULE_VERSION_REGEX }.freeze

    before { require_packages_enabled! }

    helpers do
      def case_decode(str)
        str.gsub(/![[:alpha:]]/) { |s| s[1..].upcase }
      end

      def find_module
        module_name = case_decode params[:module_name]
        bad_request!('Module Name') if module_name.blank?

        mod = ::Packages::Go::ModuleFinder.new(user_project, module_name).execute

        not_found! unless mod

        mod
      end

      def find_version
        module_version = case_decode params[:module_version]
        ver = ::Packages::Go::VersionFinder.new(find_module).find(module_version)

        not_found! unless ver&.valid?

        ver
      end

      def find_project!(id)
        project = find_project(id)

        ability = job_token_authentication? ? :build_read_project : :read_project

        if can?(current_user, ability, project)
          project
        elsif current_user.nil?
          unauthorized!
        else
          not_found!('Project')
        end
      end
    end

    params do
      requires :id, type: String, desc: 'The ID of a project'
      requires :module_name, type: String, desc: 'Module name'
    end
    route_setting :authentication, job_token_allowed: true
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      before do
        authorize_read_package!
        authorize_packages_feature!
      end

      namespace ':id/packages/go/*module_name/@v' do
        desc 'Get all tagged versions for a given Go module' do
          detail 'See `go help goproxy`, GET $GOPROXY/<module>/@v/list'
        end
        get 'list' do
          mod = find_module

          content_type 'text/plain'
          mod.versions.map { |t| t.name }.join("\n")
        end

        desc 'Get information about the given module version' do
          detail 'See `go help goproxy`, GET $GOPROXY/<module>/@v/<version>.info'
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
          detail 'See `go help goproxy`, GET $GOPROXY/<module>/@v/<version>.mod'
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
          detail 'See `go help goproxy`, GET $GOPROXY/<module>/@v/<version>.zip'
        end
        params do
          requires :module_version, type: String, desc: 'Module version'
        end
        get ':module_version.zip', requirements: MODULE_VERSION_REQUIREMENTS do
          ver = find_version

          suffix_len = ver.mod.path == '' ? 0 : ver.mod.path.length + 1

          s = Zip::OutputStream.write_buffer do |zip|
            ver.files.each do |file|
              zip.put_next_entry "#{ver.mod.name}@#{ver.name}/#{file.path[suffix_len...]}"
              zip.write ver.blob_at(file.path)
            end
          end

          header['Content-Disposition'] = ActionDispatch::Http::ContentDisposition.format(disposition: 'attachment', filename: ver.name + '.zip')
          header['Content-Transfer-Encoding'] = 'binary'
          content_type 'text/plain'
          # content_type 'application/zip'
          status :ok
          body s.string
        end
      end
    end
  end
end
