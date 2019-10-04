# frozen_string_literal: true

module API
  class ConanPackages < Grape::API
    helpers ::API::Helpers::PackagesHelpers

    before do
      not_found! unless Feature.enabled?(:conan_package_registry)
      require_packages_enabled!

      # Personal access token will be extracted from Bearer or Basic authorization
      # in the overriden find_personal_access_token helper
      authenticate!
    end

    namespace 'packages/conan/v1/users/' do
      format :txt

      desc 'Authenticate user against conan CLI' do
        detail 'This feature was introduced in GitLab 12.2'
      end
      get 'authenticate' do
        token = ::Gitlab::ConanToken.from_personal_access_token(access_token)
        token.to_jwt
      end

      desc 'Check for valid user credentials per conan CLI' do
        detail 'This feature was introduced in GitLab 12.3'
      end
      get 'check_credentials' do
        authenticate!
        :ok
      end
    end

    namespace 'packages/conan/v1/' do
      desc 'Ping the Conan API' do
        detail 'This feature was introduced in GitLab 12.2'
      end
      get 'ping' do
        header 'X-Conan-Server-Capabilities', [].join(',')
      end

      desc 'Search for packages' do
        detail 'This feature was introduced in GitLab 12.3'
      end
      params do
        requires :q, type: String, desc: 'Search query'
      end
      get 'conans/search' do
        service = ::Packages::Conan::SearchService.new(current_user, query: params[:q]).execute
        service.payload
      end
    end

    namespace 'packages/conan/v1/conans/*url_recipe' do
      before do
        render_api_error!("Invalid recipe", 400) unless valid_url_recipe?(params[:url_recipe])
      end
      params do
        requires :url_recipe, type: String, desc: 'Package recipe'
      end

      # Get the recipe manifest
      # returns the download urls for the existing recipe in the registry
      #
      # the manifest is a hash of { filename: url }
      # where the url is the download url for the file
      desc 'Package Digest' do
        detail 'This feature was introduced in GitLab 12.3'
      end
      get 'packages/:package_id/digest' do
        render_api_error!("No recipe manifest found", 404)
      end

      desc 'Recipe Digest' do
        detail 'This feature was introduced in GitLab 12.3'
      end
      get 'digest' do
        render_api_error!("No recipe manifest found", 404)
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
      params do
        requires :package_id, type: String, desc: 'Conan package ID'
      end
      post 'packages/:package_id/upload_urls' do
        status 200
        {
          'conaninfo.txt':      "#{base_file_url}/#{params[:url_recipe]}/-/0/package/#{params[:package_id]}/0/conaninfo.txt",
          'conanmanifest.txt': "#{base_file_url}/#{params[:url_recipe]}/-/0/package/#{params[:package_id]}/0/conanmanifest.txt",
          'conan_package.tgz': "#{base_file_url}/#{params[:url_recipe]}/-/0/package/#{params[:package_id]}/0/conan_package.tgz"
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
        {}
      end

      desc 'Package Snapshot' do
        detail 'This feature was introduced in GitLab 12.3'
      end
      get 'packages/:package_id' do
        {}
      end
    end

    helpers do
      def base_file_url
        "#{::Settings.gitlab.base_url}/api/v4/packages/conan/v1/files"
      end

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

      def valid_url_recipe?(recipe_url)
        recipe_url =~ %r{\A(([\w](\.|\+|-)?)*(\/?)){4}\z}
      end
    end
  end
end
