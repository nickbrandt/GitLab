# frozen_string_literal: true

module EE
  module GroupPolicy
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    prepended do
      with_scope :subject
      condition(:ldap_synced) { @subject.ldap_synced? }
      condition(:epics_available) { @subject.feature_available?(:epics) }
      condition(:contribution_analytics_available) do
        @subject.feature_available?(:contribution_analytics)
      end

      condition(:cycle_analytics_available) do
        @subject.feature_available?(:cycle_analytics_for_groups)
      end

      condition(:can_owners_manage_ldap, scope: :global) do
        ::Gitlab::CurrentSettings.allow_group_owners_to_manage_ldap?
      end

      condition(:memberships_locked_to_ldap, scope: :global) do
        ::Gitlab::CurrentSettings.lock_memberships_to_ldap?
      end

      condition(:security_dashboard_feature_disabled) do
        !@subject.feature_available?(:security_dashboard)
      end

      condition(:needs_new_sso_session) do
        sso_enforcement_prevents_access?
      end

      condition(:ip_enforcement_prevents_access) do
        !::Gitlab::IpRestriction::Enforcer.new(subject).allows_current_ip?
      end

      condition(:dependency_proxy_available) do
        @subject.feature_available?(:dependency_proxy)
      end

      rule { reporter }.policy do
        enable :admin_list
        enable :admin_board
      end

      rule { maintainer }.policy do
        enable :create_jira_connect_subscription
      end

      rule { can?(:read_group) & contribution_analytics_available }
        .enable :read_group_contribution_analytics

      rule { reporter & cycle_analytics_available }
        .enable :read_group_cycle_analytics

      rule { can?(:read_group) & dependency_proxy_available }
        .enable :read_dependency_proxy

      rule { developer & dependency_proxy_available }
        .enable :admin_dependency_proxy

      rule { can?(:read_group) & epics_available }.enable :read_epic

      rule { reporter & epics_available }.policy do
        enable :create_epic
        enable :admin_epic
        enable :update_epic
      end

      rule { owner & epics_available }.enable :destroy_epic

      rule { ~can?(:read_cross_project) }.policy do
        prevent :read_group_contribution_analytics
        prevent :read_epic
        prevent :create_epic
        prevent :admin_epic
        prevent :update_epic
        prevent :destroy_epic
      end

      rule { auditor }.enable :read_group

      rule { admin | owner }.enable :admin_group_saml

      rule { admin | (can_owners_manage_ldap & owner) }.enable :admin_ldap_group_links

      rule { ldap_synced }.prevent :admin_group_member

      rule { ldap_synced & (admin | owner) }.enable :update_group_member

      rule { ldap_synced & (admin | (can_owners_manage_ldap & owner)) }.enable :override_group_member

      rule { memberships_locked_to_ldap & ~admin }.policy do
        prevent :admin_group_member
        prevent :update_group_member
        prevent :override_group_member
      end

      rule { developer }.policy do
        enable :read_group_security_dashboard
      end

      rule { security_dashboard_feature_disabled }.policy do
        prevent :read_group_security_dashboard
      end

      rule { needs_new_sso_session }.policy do
        prevent :read_group
      end

      rule { ip_enforcement_prevents_access & ~owner }.policy do
        prevent :read_group
      end
    end

    override :lookup_access_level!
    def lookup_access_level!
      return ::GroupMember::NO_ACCESS if needs_new_sso_session?

      super
    end

    def sso_enforcement_prevents_access?
      return false unless subject.persisted?
      return false if user&.admin?

      ::Gitlab::Auth::GroupSaml::SsoEnforcer.group_access_restricted?(subject)
    end
  end
end
