# frozen_string_literal: true
module API
  class GoProxy < Grape::API
    helpers ::API::Helpers::PackagesHelpers

    SEMVER_REGEX = /v(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(-[-.A-Z0-9]+)?(\+[-.A-Z0-9]+)?/i.freeze
    SEMVER_TAG_REGEX = Regexp.new("^#{SEMVER_REGEX.source}$").freeze
    MODULE_VERSION_REQUIREMENTS = { :module_version => SEMVER_REGEX }

    helpers do
      def project_package_base
        @project_package_base ||= Gitlab::Routing.url_helpers.project_url(user_project).split('://', 2)[1]
      end

      def check_module_name
        module_name = params[:module_name].gsub(/![[:alpha:]]/) { |s| s[1..].upcase }

        bad_request!('Module Name') if module_name.blank?

        if module_name == project_package_base
          [module_name, '']
        elsif module_name.start_with?(project_package_base + '/')
          [module_name, module_name[(project_package_base.length+1)..]]
        else
          not_found!
        end
      end

      def module_version?(project, path, module_name, tag)
        return false unless SEMVER_TAG_REGEX.match?(tag.name)
        return false unless tag.dereferenced_target

        gomod = project.repository.blob_at(tag.dereferenced_target.sha, path + '/go.mod')
        return false unless gomod

        mod = gomod.data.split("\n", 2).first
        mod == 'module ' + module_name
      end

      def module_versions(project, path, module_name)
        project.repository.tags.filter { |tag| module_version?(project, path, module_name, tag) }
      end
    end

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      namespace ':id/packages/go/*module_name/@v' do
        before do
        end

        desc 'Get all tagged versions for a given Go module' do
          detail 'See `go help goproxy`, GET $GOPROXY/<module>/@v/list'
        end
        get 'list' do
          module_name, path = check_module_name

          content_type 'text/plain'
          module_versions(user_project, path, module_name).map { |t| t.name }.join("\n")
        end

        desc 'Get information about the given module version' do
          detail 'See `go help goproxy`, GET $GOPROXY/<module>/@v/<version>.info'
        end
        get ':module_version.info', :requirements => MODULE_VERSION_REQUIREMENTS do
          module_name, path = check_module_name

          tag = user_project.repository.tags.filter { |tag| tag.name == params[:module_version] }.first
          not_found! unless tag && module_version?(user_project, path, module_name, tag)

          {
            "Version" => tag.name,
            "Time" => tag.dereferenced_target.committed_date
          }
        end

        desc 'Get the module file of the given module version' do
          detail 'See `go help goproxy`, GET $GOPROXY/<module>/@v/<version>.mod'
        end
        get ':module_version.mod', :requirements => MODULE_VERSION_REQUIREMENTS do
          module_name, path = check_module_name

          tag = user_project.repository.tags.filter { |tag| tag.name == params[:module_version] }.first
          not_found! unless tag && module_version?(user_project, path, module_name, tag)

          content_type 'text/plain'
          user_project.repository.blob_at(tag.dereferenced_target.sha, path + '/go.mod').data
        end

        desc 'Get a zip of the source of the given module version' do
          detail 'See `go help goproxy`, GET $GOPROXY/<module>/@v/<version>.zip'
        end
        get ':module_version.zip', :requirements => MODULE_VERSION_REQUIREMENTS do
          module_name, path = check_module_name

          tag = user_project.repository.tags.filter { |tag| tag.name == params[:module_version] }.first
          not_found! unless tag && module_version?(user_project, path, module_name, tag)

          sha = tag.dereferenced_target.sha
          tree = user_project.repository.tree(sha, path, recursive: true).entries.filter { |e| e.type == :blob }
          nested = tree.filter { |e| e.name == 'go.mod' && !(path == '' && e.path == 'go.mod' || e.path == path + '/go.mod') }.map { |e| e.path[0..-7] }
          files = tree.filter { |e| !nested.any? { |n| e.path.start_with? n } }

          s = Zip::OutputStream.write_buffer do |zip|
            files.each do |file|
              zip.put_next_entry(file.path)
              zip.write user_project.repository.blob_at(sha, file.path).data
            end
          end

          header['Content-Disposition'] = ActionDispatch::Http::ContentDisposition.format(disposition: 'attachment', filename: tag.name + '.zip')
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