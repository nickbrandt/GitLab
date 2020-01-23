# frozen_string_literal: true

module API
  class ProtectedEnvironments < Grape::API
    include PaginationParams

    ENVIRONMENT_ENDPOINT_REQUIREMENTS = API::NAMESPACE_OR_PROJECT_REQUIREMENTS.merge(name: API::NO_SLASH_URL_PART_REGEX)

    before { authorize_admin_project }

    before do
      not_found! unless Feature.enabled?(:protected_environments_api, user_project)
    end

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end

    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc "Get a project's protected environments" do
        detail 'This feature is gated by the :protected_environments_api feature flag.'
        success ::EE::API::Entities::ProtectedEnvironment
      end
      params do
        use :pagination
      end
      get ':id/protected_environments' do
        protected_environments = user_project.protected_environments.sorted_by_name

        present paginate(protected_environments), with: ::EE::API::Entities::ProtectedEnvironment, project: user_project
      end

      desc 'Get a single protected environment' do
        detail 'This feature is gated by the :protected_environments_api feature flag.'
        success ::EE::API::Entities::ProtectedEnvironment
      end
      params do
        requires :name, type: String, desc: 'The name of the protected environment'
      end
      get ':id/protected_environments/:name', requirements: ENVIRONMENT_ENDPOINT_REQUIREMENTS do
        protected_environment = user_project.protected_environments.find_by_name!(params[:name])

        present protected_environment, with: ::EE::API::Entities::ProtectedEnvironment, project: user_project
      end
    end
  end
end
