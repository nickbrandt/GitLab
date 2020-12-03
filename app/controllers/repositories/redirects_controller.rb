# frozen_string_literal: true

module Repositories
  class RedirectsController < Repositories::GitHttpController
    extend ::Gitlab::Utils::Override

    skip_before_action :verify_workhorse_api!
    around_action :set_session_storage, only: :redirect_web

    def redirect_web
      redirect_to with_query(container.web_url(only_path: true))
    end

    def redirect_git
      path = "/#{repository_path}/info/refs"
      path = "/-/push_from_secondary/#{params[:geo_node_id]}#{path}" if params[:geo_node_id]

      redirect_to with_query(path)
    end

    private

    def with_query(path)
      path += "?#{request.query_string}" if request.query_string.present?
      path
    end

    override :repository_path
    def repository_path
      @repository_path ||= super.delete_suffix('.git') + '.git'
    end

    # Authorize as if we were downloading
    override :git_command
    def git_command
      'git-upload-pack'
    end

    override :authenticate_user
    def authenticate_user
      if action_name == 'redirect_web'
        @authentication_result = Gitlab::Auth::Result.new(current_user, nil, :gitlab_or_ldap, Gitlab::Auth.read_only_authentication_abilities)
      else
        super
      end
    end
  end
end
