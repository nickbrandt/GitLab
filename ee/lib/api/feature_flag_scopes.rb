# frozen_string_literal: true

module API
  class FeatureFlagScopes < Grape::API
    include PaginationParams

    ENVIRONMENT_SCOPE_ENDPOINT_REQUIREMETS = FeatureFlags::FEATURE_FLAG_ENDPOINT_REQUIREMENTS
      .merge(environment_scope: API::NO_SLASH_URL_PART_REGEX)

    before do
      not_found! unless Feature.enabled?(:feature_flag_api, user_project)
      authorize_read_feature_flags!
    end

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource 'projects/:id', requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      resource :feature_flag_scopes do
        desc 'Get all effective feature flags under the environment' do
          detail 'This feature is going to be introduced in GitLab 12.5 if `feature_flag_api` feature flag is removed'
          success EE::API::Entities::FeatureFlag::DetailedScope
        end
        params do
          requires :environment, type: String, desc: 'The environment name'
        end
        get do
          present scopes_for_environment, with: EE::API::Entities::FeatureFlag::DetailedScope
        end
      end

      params do
        requires :name, type: String, desc: 'The name of the feature flag'
      end
      resource 'feature_flags/:name', requirements: FeatureFlags::FEATURE_FLAG_ENDPOINT_REQUIREMENTS do
        resource :scopes do
          desc 'Get all scopes of a feature flag' do
            detail 'This feature is going to be introduced in GitLab 12.5 if `feature_flag_api` feature flag is removed'
            success EE::API::Entities::FeatureFlag::Scope
          end
          params do
            use :pagination
          end
          get do
            present paginate(feature_flag.scopes), with: EE::API::Entities::FeatureFlag::Scope
          end

          params do
            requires :environment_scope, type: String, desc: 'URL-encoded environment scope'
          end
          resource ':environment_scope', requirements: ENVIRONMENT_SCOPE_ENDPOINT_REQUIREMETS do
            desc 'Get a scope of a feature flag' do
              detail 'This feature is going to be introduced in GitLab 12.5 if `feature_flag_api` feature flag is removed'
              success EE::API::Entities::FeatureFlag::Scope
            end
            get do
              present scope, with: EE::API::Entities::FeatureFlag::Scope
            end

            desc 'Delete a scope from a feature flag' do
              detail 'This feature is going to be introduced in GitLab 12.5 if `feature_flag_api` feature flag is removed'
              success EE::API::Entities::FeatureFlag::Scope
            end
            delete do
              authorize_update_feature_flag!

              param = { scopes_attributes: [{ id: scope.id, _destroy: true }] }

              result = ::FeatureFlags::UpdateService
                .new(user_project, current_user, param)
                .execute(feature_flag)

              if result[:status] == :success
                status :no_content
              else
                render_api_error!(result[:message], result[:http_status])
              end
            end
          end
        end
      end
    end

    helpers do
      def authorize_read_feature_flags!
        authorize! :read_feature_flag, user_project
      end

      def authorize_update_feature_flag!
        authorize! :update_feature_flag, feature_flag
      end

      def feature_flag
        @feature_flag ||= user_project.operations_feature_flags
                                      .find_by_name!(params[:name])
      end

      def scope
        @scope ||= feature_flag.scopes
          .find_by_environment_scope!(CGI.unescape(params[:environment_scope]))
      end

      def scopes_for_environment
        Operations::FeatureFlagScope
          .for_unleash_client(user_project, params[:environment])
      end
    end
  end
end
