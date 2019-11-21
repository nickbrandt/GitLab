# frozen_string_literal: true

module EE
  module API
    module Helpers
      extend ::Gitlab::Utils::Override
      include ::Gitlab::Utils::StrongMemoize

      def require_node_to_be_enabled!
        forbidden! 'Geo node is disabled.' unless ::Gitlab::Geo.current_node&.enabled?
      end

      def gitlab_geo_node_token?
        headers['Authorization']&.start_with?(::Gitlab::Geo::BaseRequest::GITLAB_GEO_AUTH_TOKEN_TYPE)
      end

      def authenticate_by_gitlab_geo_node_token!
        unauthorized! unless authorization_header_valid?
      rescue ::Gitlab::Geo::InvalidDecryptionKeyError, ::Gitlab::Geo::InvalidSignatureTimeError => e
        render_api_error!(e.to_s, 401)
      end

      def check_gitlab_geo_request_ip!
        unauthorized! unless ::Gitlab::Geo.allowed_ip?(request.ip)
      end

      override :current_user
      def current_user
        strong_memoize(:current_user) do
          user = super

          if user
            ::Gitlab::Database::LoadBalancing::RackMiddleware
              .stick_or_unstick(env, :user, user.id)
          end

          user
        end
      end

      def authorization_header_valid?
        auth_header = headers['Authorization']
        return unless auth_header

        scope = ::Gitlab::Geo::JwtRequestDecoder.new(auth_header).decode.try { |x| x[:scope] }
        scope == ::Gitlab::Geo::API_SCOPE
      end

      def check_project_feature_available!(feature)
        not_found! unless user_project.feature_available?(feature)
      end

      def authorize_change_param(subject, *keys)
        keys.each do |key|
          authorize!("change_#{key}".to_sym, subject) if params.has_key?(key)
        end
      end

      def check_sha_param!(params, merge_request)
        if params[:sha] && merge_request.diff_head_sha != params[:sha]
          render_api_error!("SHA does not match HEAD of source branch: #{merge_request.diff_head_sha}", 409)
        end
      end

      # Normally, only admin users should have access to see LDAP
      # groups. However, due to the "Allow group owners to manage LDAP-related
      # group settings" setting, any group owner can sync LDAP groups with
      # their project.
      #
      # In the future, we should also check that the user has access to manage
      # a specific group so that we can use the Ability class.
      def authenticated_with_ldap_admin_access!
        authenticate!

        forbidden! unless current_user.admin? ||
            ::Gitlab::CurrentSettings.current_application_settings
              .allow_group_owners_to_manage_ldap
      end

      override :find_project!
      def find_project!(id)
        project = find_project(id)

        # CI job token authentication:
        # this method grants limited privileged for admin users
        # admin users can only access project if they are direct member
        ability = job_token_authentication? ? :build_read_project : :read_project

        if can?(current_user, ability, project)
          project
        else
          not_found!('Project')
        end
      end

      override :find_group!
      def find_group!(id)
        # CI job token authentication:
        # currently we do not allow any group access for CI job token
        if job_token_authentication?
          not_found!('Group')
        else
          super
        end
      end

      override :find_project_issue
      # rubocop: disable CodeReuse/ActiveRecord
      def find_project_issue(iid, project_id = nil)
        project = project_id ? find_project!(project_id) : user_project

        ::IssuesFinder.new(current_user, project_id: project.id).find_by!(iid: iid)
      end
      # rubocop: enable CodeReuse/ActiveRecord

      private

      override :project_finder_params_ee
      def project_finder_params_ee
        if params[:with_security_reports].present?
          { with_security_reports: true }
        else
          {}
        end
      end

      override :send_git_archive
      def send_git_archive(repository, **kwargs)
        EE::AuditEvents::RepositoryDownloadStartedAuditEventService.new(
          current_user,
          repository.project,
          ip_address
        ).for_project.security_event

        super
      end

      def private_token
        params[::APIGuard::PRIVATE_TOKEN_PARAM] || env[::APIGuard::PRIVATE_TOKEN_HEADER]
      end

      def job_token_authentication?
        initial_current_user && @current_authenticated_job.present? # rubocop:disable Gitlab/ModuleWithInstanceVariables
      end

      # Returns the job associated with the token provided for
      # authentication, if any
      def current_authenticated_job
        @current_authenticated_job
      end

      def warden
        env['warden']
      end

      # Check if the request is GET/HEAD, or if CSRF token is valid.
      def verified_request?
        ::Gitlab::RequestForgeryProtection.verified?(env)
      end

      # Check the Rails session for valid authentication details
      def find_user_from_warden
        warden.try(:authenticate) if verified_request?
      end

      def geo_token
        ::Gitlab::Geo.current_node.system_hook.token
      end

      def authorize_manage_saml!(group)
        unauthorized! unless can?(current_user, :admin_group_saml, group)
      end

      def check_group_saml_configured
        forbidden!('Group SAML not enabled.') unless ::Gitlab::Auth::GroupSaml::Config.enabled?
      end
    end
  end
end
