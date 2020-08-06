# frozen_string_literal: true

module API
  class PersonalAccessTokens < Grape::API::Instance
    include ::API::PaginationParams

    desc 'Get all Personal Access Tokens' do
      detail 'This feature was added in GitLab 13.3'
      success Entities::PersonalAccessToken
    end
    params do
      optional :user_id, type: Integer, desc: 'User ID'

      use :pagination
    end

    before do
      authenticate!
      restrict_non_admins! unless current_user.admin?
    end

    helpers do
      def finder_params(current_user)
        current_user.admin? ? { user: user(params[:user_id]) } : { user: current_user }
      end

      def user(user_id)
        UserFinder.new(user_id).find_by_id
      end

      def restrict_non_admins!
        return if params[:user_id].blank?

        unauthorized! unless Ability.allowed?(current_user, :read_user_personal_access_tokens, user(params[:user_id]))
      end

      def authenticate!
        unauthorized! unless ::License.feature_available?(:personal_access_token_api_management)
        super
      end
    end

    get :personal_access_tokens do
      tokens = PersonalAccessTokensFinder.new(finder_params(current_user), current_user).execute

      present paginate(tokens), with: Entities::PersonalAccessToken
    end
  end
end
