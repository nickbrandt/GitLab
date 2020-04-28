# frozen_string_literal: true

# PHP composer support (https://getcomposer.org/)
module API
  class ComposerPackages < Grape::API
    helpers ::API::Helpers::PackagesManagerClientsHelpers
    helpers ::API::Helpers::RelatedResourcesHelpers
    helpers ::API::Helpers::Packages::BasicAuthHelpers
    include ::API::Helpers::Packages::BasicAuthHelpers::Constants

    content_type :json, 'application/json'
    default_format :json

    COMPOSER_ENDPOINT_REQUIREMENTS = {
      package_name: API::NO_SLASH_URL_PART_REGEX
    }.freeze

    default_format :json

    rescue_from ArgumentError do |e|
      render_api_error!(e.message, 400)
    end

    rescue_from ActiveRecord::RecordInvalid do |e|
      render_api_error!(e.message, 400)
    end

    before do
      require_packages_enabled!
    end

    params do
      requires :id, type: String, desc: 'The ID of a group'
    end

    resource :group, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      before do
        unless ::Feature.enabled?(:composer_packages, user_group)
          not_found!
        end

        authorize_packages_feature!(user_group)
      end

      desc 'Composer packages endpoint at group level'

      route_setting :authentication, job_token_allowed: true

      get ':id/-/packages/composer/packages' do
      end

      desc 'Composer packages endpoint at group level for packages list'

      params do
        requires :sha, type: String, desc: 'Shasum of current json'
      end

      route_setting :authentication, job_token_allowed: true

      get ':id/-/packages/composer/p/:sha' do
      end

      desc 'Composer packages endpoint at group level for package versions metadata'

      route_setting :authentication, job_token_allowed: true

      get ':id/-/packages/composer/*package_name', requirements: COMPOSER_ENDPOINT_REQUIREMENTS, file_path: true do
      end
    end

    params do
      requires :id, type: Integer, desc: 'The ID of a project'
    end

    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      before do
        unless ::Feature.enabled?(:composer_packages, authorized_user_project)
          not_found!
        end

        authorize_packages_feature!(authorized_user_project)
      end

      desc 'Composer packages endpoint for registering packages'

      params do
        optional :branch, type: String, desc: 'The name of the branch'
        optional :tag, type: String, desc: 'The name of the tag'
      end

      namespace ':id/packages/composer' do
        post do
          authorize_create_package!(authorized_user_project)

          created!
        end
      end
    end
  end
end
