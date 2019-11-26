# frozen_string_literal: true
module API
  class MavenPackages < Grape::API
    MAVEN_ENDPOINT_REQUIREMENTS = {
      file_name: API::NO_SLASH_URL_PART_REGEX
    }.freeze

    content_type :md5, 'text/plain'
    content_type :sha1, 'text/plain'
    content_type :binary, 'application/octet-stream'

    rescue_from ActiveRecord::RecordInvalid do |e|
      render_api_error!(e.message, 400)
    end

    before do
      require_packages_enabled!
      authenticate_non_get!
    end

    helpers ::API::Helpers::PackagesHelpers

    helpers do
      def extract_format(file_name)
        name, _, format = file_name.rpartition('.')

        if %w(md5 sha1).include?(format)
          [name, format]
        else
          [file_name, nil]
        end
      end

      def verify_package_file(package_file, uploaded_file)
        stored_sha1 = Digest::SHA256.hexdigest(package_file.file_sha1)
        expected_sha1 = uploaded_file.sha256

        if stored_sha1 == expected_sha1
          no_content!
        else
          conflict!
        end
      end

      def find_project_by_path(path)
        project_path = path.rpartition('/').first
        Project.find_by_full_path(project_path)
      end
    end

    desc 'Download the maven package file at instance level' do
      detail 'This feature was introduced in GitLab 11.6'
    end
    params do
      requires :path, type: String, desc: 'Package path'
      requires :file_name, type: String, desc: 'Package file name'
    end
    route_setting :authentication, job_token_allowed: true
    get 'packages/maven/*path/:file_name', requirements: MAVEN_ENDPOINT_REQUIREMENTS do
      file_name, format = extract_format(params[:file_name])

      # To avoid name collision we require project path and project package be the same.
      # For packages that have different name from the project we should use
      # the endpoint that includes project id
      project = find_project_by_path(params[:path])

      authorize_read_package!(project)

      package = ::Packages::MavenPackageFinder
        .new(params[:path], current_user, project: project).execute!

      authorize_packages_feature!(package.project)

      package_file = ::Packages::PackageFileFinder
        .new(package, file_name).execute!

      case format
      when 'md5'
        package_file.file_md5
      when 'sha1'
        package_file.file_sha1
      when nil
        present_carrierwave_file!(package_file.file)
      end
    end

    desc 'Download the maven package file at a group level' do
      detail 'This feature was introduced in GitLab 11.7'
    end
    params do
      requires :id, type: String, desc: 'The ID of a group'
    end
    resource :groups, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      params do
        requires :path, type: String, desc: 'Package path'
        requires :file_name, type: String, desc: 'Package file name'
      end
      route_setting :authentication, job_token_allowed: true
      get ':id/-/packages/maven/*path/:file_name', requirements: MAVEN_ENDPOINT_REQUIREMENTS do
        file_name, format = extract_format(params[:file_name])

        group = find_group(params[:id])

        not_found!('Group') unless can?(current_user, :read_group, group)

        package = ::Packages::MavenPackageFinder
          .new(params[:path], current_user, group: group).execute!

        authorize_packages_feature!(package.project)
        authorize_read_package!(package.project)

        package_file = ::Packages::PackageFileFinder
          .new(package, file_name).execute!

        case format
        when 'md5'
          package_file.file_md5
        when 'sha1'
          package_file.file_sha1
        when nil
          present_carrierwave_file!(package_file.file)
        end
      end
    end

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      before do
        authorize_packages_feature!(user_project)
      end

      desc 'Download the maven package file' do
        detail 'This feature was introduced in GitLab 11.3'
      end
      params do
        requires :path, type: String, desc: 'Package path'
        requires :file_name, type: String, desc: 'Package file name'
      end
      route_setting :authentication, job_token_allowed: true
      get ':id/packages/maven/*path/:file_name', requirements: MAVEN_ENDPOINT_REQUIREMENTS do
        authorize_read_package!(user_project)

        file_name, format = extract_format(params[:file_name])

        package = ::Packages::MavenPackageFinder
          .new(params[:path], current_user, project: user_project).execute!

        package_file = ::Packages::PackageFileFinder
          .new(package, file_name).execute!

        case format
        when 'md5'
          package_file.file_md5
        when 'sha1'
          package_file.file_sha1
        when nil
          present_carrierwave_file!(package_file.file)
        end
      end

      desc 'Upload the maven package file' do
        detail 'This feature was introduced in GitLab 11.3'
      end
      params do
        requires :path, type: String, desc: 'Package path'
        requires :file_name, type: String, desc: 'Package file name', regexp: Gitlab::Regex.maven_file_name_regex
      end
      route_setting :authentication, job_token_allowed: true
      put ':id/packages/maven/*path/:file_name/authorize', requirements: MAVEN_ENDPOINT_REQUIREMENTS do
        authorize_create_package!

        require_gitlab_workhorse!
        Gitlab::Workhorse.verify_api_request!(headers)

        status 200
        content_type Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE
        ::Packages::PackageFileUploader.workhorse_authorize(has_length: true)
      end

      desc 'Upload the maven package file' do
        detail 'This feature was introduced in GitLab 11.3'
      end
      params do
        requires :path, type: String, desc: 'Package path'
        requires :file_name, type: String, desc: 'Package file name', regexp: Gitlab::Regex.maven_file_name_regex
        optional 'file.path', type: String, desc: %q(path to locally stored body (generated by Workhorse))
        optional 'file.name', type: String, desc: %q(real filename as send in Content-Disposition (generated by Workhorse))
        optional 'file.type', type: String, desc: %q(real content type as send in Content-Type (generated by Workhorse))
        optional 'file.size', type: Integer, desc: %q(real size of file (generated by Workhorse))
        optional 'file.md5', type: String, desc: %q(md5 checksum of the file (generated by Workhorse))
        optional 'file.sha1', type: String, desc: %q(sha1 checksum of the file (generated by Workhorse))
        optional 'file.sha256', type: String, desc: %q(sha256 checksum of the file (generated by Workhorse))
      end
      route_setting :authentication, job_token_allowed: true
      put ':id/packages/maven/*path/:file_name', requirements: MAVEN_ENDPOINT_REQUIREMENTS do
        authorize_create_package!
        require_gitlab_workhorse!

        file_name, format = extract_format(params[:file_name])

        uploaded_file = UploadedFile.from_params(params, :file, ::Packages::PackageFileUploader.workhorse_local_upload_path)
        bad_request!('Missing package file!') unless uploaded_file

        package = ::Packages::FindOrCreateMavenPackageService
          .new(user_project, current_user, params).execute

        case format
        when 'sha1'
          # After uploading a file, Maven tries to upload a sha1 and md5 version of it.
          # Since we store md5/sha1 in database we simply need to validate our hash
          # against one uploaded by Maven. We do this for `sha1` format.
          package_file = ::Packages::PackageFileFinder
            .new(package, file_name).execute!

          verify_package_file(package_file, uploaded_file)
        when nil
          file_params = {
            file:      uploaded_file,
            size:      params['file.size'],
            file_name: file_name,
            file_type: params['file.type'],
            file_sha1: params['file.sha1'],
            file_md5:  params['file.md5']
          }

          ::Packages::CreatePackageFileService.new(package, file_params).execute
        end
      end
    end
  end
end
