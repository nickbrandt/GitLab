# frozen_string_literal: true
module API
  class GoProxy < Grape::API
    helpers ::API::Helpers::PackagesHelpers

    MODULE_VERSION_REQUIREMENTS = { module_version: ::Packages::GoModuleVersion::SEMVER_REGEX }.freeze

    before { require_packages_enabled! }

    helpers do
      def find_module
        module_name = params[:module_name].gsub(/![[:alpha:]]/) { |s| s[1..].upcase }

        bad_request!('Module Name') if module_name.blank?

        mod = ::Packages::GoModule.new user_project, module_name
        not_found! if mod.path.nil?

        mod
      end
    end

    params do
      requires :id, type: String, desc: 'The ID of a project'
      requires :module_name, type: String, desc: 'Module name'
    end
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
          mod = find_module

          ver = mod.find_version params[:module_version]
          not_found! unless ver

          present ::Packages::Go::ModuleVersionPresenter.new(ver), with: EE::API::Entities::GoModuleVersion
        end

        desc 'Get the module file of the given module version' do
          detail 'See `go help goproxy`, GET $GOPROXY/<module>/@v/<version>.mod'
        end
        params do
          requires :module_version, type: String, desc: 'Module version'
        end
        get ':module_version.mod', requirements: MODULE_VERSION_REQUIREMENTS do
          mod = find_module

          ver = mod.find_version params[:module_version]
          not_found! unless ver

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
          mod = find_module

          ver = mod.find_version params[:module_version]
          not_found! unless ver

          s = Zip::OutputStream.write_buffer do |zip|
            ver.files.each do |file|
              zip.put_next_entry file.path
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
