module EE
  module API
    module Helpers
      def current_user
        return @current_user if defined?(@current_user)

        user = super

        ::Gitlab::Database::LoadBalancing::RackMiddleware
          .stick_or_unstick(env, :user, user.id) if user

        user
      end

      def check_project_feature_available!(feature)
        not_found! unless user_project.feature_available?(feature)
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
    end
  end
end
