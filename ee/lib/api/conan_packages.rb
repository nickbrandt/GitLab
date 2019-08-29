# frozen_string_literal: true

module API
  class ConanPackages < Grape::API
    content_type :txt, 'text/plain'
    content_type :md5, 'text/plain'
    content_type :sha1, 'text/plain'
    content_type :binary, 'application/octet-stream'

    rescue_from ActiveRecord::RecordInvalid do |e|
      render_api_error!(e.message, 400)
    end

    helpers ::API::Helpers::PackagesHelpers

    helpers do
      def base_file_url
        "#{::Settings.gitlab.base_url}/api/v4/packages/conan/v1/files"
      end

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

      def parse_recipe(url_recipe)
        split_recipe = url_recipe.split('/')
        {
          package_name: split_recipe[0],
          version: split_recipe[1],
          pkg_username: split_recipe[2],
          channel: split_recipe[3]
        }
      end

      def generate_recipe(url_recipe)
        recipe_obj = parse_recipe(url_recipe)
        "#{recipe_obj[:package_name]}/#{recipe_obj[:version]}@#{recipe_obj[:pkg_username]}/#{recipe_obj[:channel]}"
      end

      def generate_recipe_url(recipe)
        recipe.tr('@', '/')
      end

      def find_project_by_recipe(url_recipe)
        project_path = parse_recipe(url_recipe)[:pkg_username].tr('.', '/')
        Project.find_by_full_path(project_path)
      end
    end

    before do
      Rails.logger.info '-----------------------------------------------'
      Rails.logger.info headers
      Rails.logger.info '---------------------------hh--------------------'
      Rails.logger.info request.body.read if request.body.is_a?(StringIO)
      Rails.logger.info '-----------------------------------------------'

      not_found! unless Feature.enabled?(:conan_package_registry)
      require_packages_enabled!

      # Personal access token will be extracted from Bearer or Basic authorization
      # in the overriden find_personal_access_token helper
      # authenticate!
    end

    namespace 'packages/conan/v1' do
      desc 'Ping the Conan API' do
        detail 'This feature was introduced in GitLab 12.2'
      end
      get 'ping' do
        header 'X-Conan-Server-Capabilities', [].join(',')
      end
    end

    namespace 'packages/conan/v1/users' do
      format :txt

      desc 'Authenticate user' do
        detail 'This feature was introduced in GitLab 12.2'
      end
      get 'authenticate' do
        token = ::Gitlab::ConanToken.from_personal_access_token(access_token)
        token.to_jwt
      end

      desc 'Check for valid user credentials' do
        detail 'This feature was introduced in GitLab 12.3'
      end
      get 'check_credentials' do
        # credentials are checked in authorize! "before" callback
        :ok
      end
    end

    namespace 'packages/conan/v1/conans/*url_recipe' do
      params do
        requires :url_recipe, type: String, desc: 'Package recipe'
      end

      # Get the recipe manifest
      # returns the download urls for the existing recipe in the registry
      #
      # the manifest is a hash of { filename: url }
      # where the url is the download url for the file
      desc 'Recipe Digest' do
        detail 'This feature was introduced in GitLab 12.3'
      end
      get 'digest' do
        recipe = generate_recipe(params[:url_recipe])
        project = find_project_by_recipe(params[:url_recipe])
        render_api_error!("No recipe manifest found", 404) unless project

        authorize!(:read_package, project)

        service = ::Packages::ConanPackageService.new(recipe, current_user, project)
        urls = service.urls(:recipe)
        Rails.logger.info "=======ccc=============================="
        Rails.logger.info urls
        render_api_error!("No recipe manifest found", 404) if urls.empty?

        urls
      end

      desc 'Package Digest' do
        detail 'This feature was introduced in GitLab 12.3'
      end
      get 'packages/:package_id/digest' do
        recipe = generate_recipe(params[:url_recipe])
        project = find_project_by_recipe(params[:url_recipe])
        render_api_error!("No recipe manifest found", 404) unless project

        authorize!(:read_package, project)

        service = ::Packages::ConanPackageService.new(recipe, current_user, project, params[:package_id])
        urls = service.urls(:package)

        render_api_error!("No recipe manifest found", 404) if urls.empty?

        urls
      end

      # Get the upload urls
      #
      # request body contains { filename: filesize } where the filename is the
      # name of the file the conan client is requesting to upload
      #
      # returns { filename: url }
      # where the url is the upload url for the file that the conan client will use
      desc 'Package Upload Urls' do
        detail 'This feature was introduced in GitLab 12.3'
      end
      post 'packages/:package_id/upload_urls' do
        status 200
        {
          'conaninfo.txt':      "#{base_file_url}/#{params[:url_recipe]}/-/0/package/#{params[:package_id]}/0/conaninfo.py",
          'conanmanifest.txt': "#{base_file_url}/#{params[:url_recipe]}/-/0/package/#{params[:package_id]}/0/conanmanifest.txt",
          'conan_package.tgz': "#{base_file_url}/#{params[:url_recipe]}/-/0/package/#{params[:package_id]}/0/conan_package.txt"
        }
      end

      desc 'Recipe Upload Urls' do
        detail 'This feature was introduced in GitLab 12.3'
      end
      post 'upload_urls' do
        status 200
        {
          'conanfile.py':      "#{base_file_url}/#{params[:url_recipe]}/-/0/export/conanfile.py",
          'conanmanifest.txt': "#{base_file_url}/#{params[:url_recipe]}/-/0/export/conanmanifest.txt"
        }
      end

      # Get the recipe snapshot
      #
      # the snapshot is a hash of { filename: md5 hash }
      # md5 hash is the has of that file. This hash is used to diff the files existing on the client
      # to determine which client files need to be uploaded if no recipe exists the snapshot is empty
      desc 'Recipe Snapshot' do
        detail 'This feature was introduced in GitLab 12.3'
      end
      get '/' do
        recipe = generate_recipe(params[:url_recipe])
        project = find_project_by_recipe(params[:url_recipe])

        return {} unless project # rubocop:disable Cop/AvoidReturnFromBlocks

        authorize!(:read_package, project)
        ::Packages::ConanPackageService.new(recipe, current_user, project).snapshot(:recipe)
      end

      desc 'Package Snapshot' do
        detail 'This feature was introduced in GitLab 12.3'
      end
      get 'packages/:package_id' do
        recipe = generate_recipe(params[:url_recipe])
        project = find_project_by_recipe(params[:url_recipe])

        return {} unless project # rubocop:disable Cop/AvoidReturnFromBlocks

        authorize!(:read_package, project)
        ::Packages::ConanPackageService.new(recipe, current_user, project, params[:package_id]).snapshot(:package)
      end
    end

    desc 'Upload the conan package file' do
      detail 'This feature was introduced in GitLab 11.3'
    end
    params do
      requires :url_recipe, type: String, desc: 'Package recipe'
      requires :path, type: String, desc: 'Package path'
    end
    # route_setting :authentication, job_token_allowed: true
    put 'packages/conan/v1/files/*url_recipe/-/*path/authorize' do
      require_gitlab_workhorse!
      Gitlab::Workhorse.verify_api_request!(headers)

      status 200
      content_type Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE
      ::Packages::PackageFileUploader.workhorse_authorize(has_length: true)
    end

    desc 'Upload package files' do
      detail 'This feature was introduced in GitLab 12.3'
    end
    params do
      requires :url_recipe, type: String, desc: 'Package recipe'
      requires :path, type: String, desc: 'Package path'
      requires :file_name, type: String, desc: 'Package file name'
      optional 'file.path', type: String, desc: %q(path to locally stored body (generated by Workhorse))
      optional 'file.name', type: String, desc: %q(real filename as send in Content-Disposition (generated by Workhorse))
      optional 'file.type', type: String, desc: %q(real content type as send in Content-Type (generated by Workhorse))
      optional 'file.size', type: Integer, desc: %q(real size of file (generated by Workhorse))
      optional 'file.md5', type: String, desc: %q(md5 checksum of the file (generated by Workhorse))
      optional 'file.sha1', type: String, desc: %q(sha1 checksum of the file (generated by Workhorse))
      optional 'file.sha256', type: String, desc: %q(sha256 checksum of the file (generated by Workhorse))
    end
    put 'packages/conan/v1/files/*url_recipe/-/*path/:file_name' do
      require_gitlab_workhorse!

      uploaded_file = UploadedFile.from_params(params, :file, ::Packages::PackageFileUploader.workhorse_local_upload_path)
      bad_request!('Missing package file!') unless uploaded_file

      recipe = generate_recipe(params[:url_recipe])
      project = find_project_by_recipe(params[:url_recipe])

      render_api_error!("No GitLab project found", 404) unless project
      authorize!(:read_package, project)

      package = ::Packages::FindOrCreateConanPackageService
        .new(project, current_user, params.merge(recipe: recipe)).execute

      file_params = {
        file:      uploaded_file,
        size:      params['file.size'],
        file_name: params[:file_name],
        file_type: params['file.type'],
        file_sha1: params['file.sha1'],
        file_md5:  params['file.md5'],
        path:      params[:path],
        recipe:    recipe
      }

      ::Packages::CreateConanPackageFileService.new(package, file_params).execute
    end

    helpers do
      def find_personal_access_token
        personal_access_token = find_personal_access_token_from_conan_jwt ||
          find_personal_access_token_from_conan_http_basic_auth

        personal_access_token || unauthorized!
      end

      # We need to override this one because it
      # looks into Bearer authorization header
      def find_oauth_access_token
      end

      def find_personal_access_token_from_conan_jwt
        jwt = Doorkeeper::OAuth::Token.from_bearer_authorization(current_request)
        return unless jwt

        token = ::Gitlab::ConanToken.decode(jwt)
        return unless token&.personal_access_token_id && token&.user_id

        PersonalAccessToken.find_by_id_and_user_id(token.personal_access_token_id, token.user_id)
      end

      def find_personal_access_token_from_conan_http_basic_auth
        encoded_credentials = headers['Authorization'].to_s.split('Basic ', 2).second
        token = Base64.decode64(encoded_credentials || '').split(':', 2).second
        return unless token

        PersonalAccessToken.find_by_token(token)
      end
    end
  end
end
