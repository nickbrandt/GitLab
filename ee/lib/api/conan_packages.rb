# frozen_string_literal: true

module API
  class ConanPackages < Grape::API
    helpers ::API::Helpers::PackagesHelpers

    before do
      Rails.logger.info '-----------------------------------------------'
      Rails.logger.info headers
      Rails.logger.info '-----------------------------------------------'
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

    namespace 'packages/conan/v1/conans/*recipe' do
      params do
        # requires :name, type: String, desc: 'Package name'
        # requires :package_version, type: Float, desc: 'Package version'
        # requires :username, type: String, desc: 'Conan package username'
        # requires :channel, type: String, desc: 'Conan package channel'
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
        # authorize read
        # service = ::Packages::ConanService.new(params[:recipe])
        # urls = service.get_conan_download_urls
        # not_found!('Recipe') unless urls
        # urls
        # {
        #   'conanfile.py': '#{Settings.build_base_gitlab_url}/api/v4/packages/conan/v1/files/#{params[:recipe]}/0/export/conanfile.py?signature=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJwYXQiOjgsInUiOjEsImp0aSI6ImRhZjM5MWVkLTA0Y2EtNDhlYS04ZmQwLTc5OGU2MzcwMWU4NCIsImlhdCI6MTU2NTY0MzM5MiwibmJmIjoxNTY1NjQzMzg3LCJleHAiOjE1NjU2NDY5OTJ9.kwA6GK5L6ykTgH_mBIL7hmVBnrvi5lEEHdLU-Pd5M_Y',
        #   'conanmanifest.txt': '#{Settings.build_base_gitlab_url}/api/v4/packages/conan/v1/files/#{params[:recipe]}/0/export/conanmanifest.txt?signature=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJwYXQiOjgsInUiOjEsImp0aSI6ImRhZjM5MWVkLTA0Y2EtNDhlYS04ZmQwLTc5OGU2MzcwMWU4NCIsImlhdCI6MTU2NTY0MzM5MiwibmJmIjoxNTY1NjQzMzg3LCJleHAiOjE1NjU2NDY5OTJ9.kwA6GK5L6ykTgH_mBIL7hmVBnrvi5lEEHdLU-Pd5M_Y'
        # }
        # {
        #   'conanmanifest.txt': '#{Settings.build_base_gitlab_url}/api/v4/packages/conan/v1/files/#{params[:recipe]}/export/conanmanifest.txt'
        # }
        render_api_error!("No recipe manifest found", 404)
      end

      desc 'Package Digest' do
        detail 'This feature was introduced in GitLab 12.3'
      end
      get 'packages/:package_id/digest' do
        render_api_error!("No package manifest found", 404)
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
          'conaninfo.txt':      "http://localhost:3001/api/v4/packages/conan/v1/files/#{params[:recipe]}/0/package/12345/0/conaninfo.py",
          'conanmanifest.txt': "http://localhost:3001/api/v4/packages/conan/v1/files/#{params[:recipe]}/0/package/12345/0/conanmanifest.txt",
          'conanmanifest.tgz': "http://localhost:3001/api/v4/packages/conan/v1/files/#{params[:recipe]}/0/package/12345/0/conan_package.txt"
        }
      end

      desc 'Recipe Upload Urls' do
        detail 'This feature was introduced in GitLab 12.3'
      end
      post 'upload_urls' do
        status 200
        {
          'conanfile.py':      "http://localhost:3001/api/v4/packages/conan/v1/files/#{params[:recipe]}/0/export/conanfile.py",
          'conanmanifest.txt': "http://localhost:3001/api/v4/packages/conan/v1/files/#{params[:recipe]}/0/export/conanmanifest.txt"
        }
      end

      # Get the recipe snapshot
      #
      # the snapshot is a hash of { filename: md5 hash }
      # md5 hash is the has of that file. This hash is used to diff the files existing on the client
      # to determine which client files need to be uploaded
      # if no recipe exists the snapshot is empty
      desc 'Recipe Snapshot' do
        detail 'This feature was introduced in GitLab 12.3'
      end
      get '/' do
        {}
      end

      desc 'Package Snapshot' do
        detail 'This feature was introduced in GitLab 12.3'
      end
      get 'packages/:package_id' do
        {}
      end
    end

    namespace 'packages/conan/v1/files/*recipe' do
      params do
        # requires :name, type: String, desc: 'Package name'
        # requires :package_version, type: String, desc: 'Package version'
        # requires :username, type: String, desc: 'Conan package username'
        # requires :channel, type: String, desc: 'Conan package channel'
      end

      desc 'Upload package files' do
        detail 'This feature was introduced in GitLab 12.3'
      end
      put '*path' do
        Rails.logger.info "***UPLOADING***"
        true
      end

      desc 'Download package files' do
        detail 'This feature was introduced in GitLab 12.3'
      end
      get '*path' do
        Rails.logger.info "***DOWNLOADING***"
        true
      end
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
