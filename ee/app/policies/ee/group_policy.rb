# frozen_string_literal: true

module EE
  module GroupPolicy
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    prepended do
      include CrudPolicyHelpers

      with_scope :subject
      condition(:ldap_synced) { @subject.ldap_synced? }
      condition(:epics_available) { @subject.feature_available?(:epics) }
      condition(:iterations_available) { @subject.feature_available?(:iterations) }
      condition(:subepics_available) { @subject.feature_available?(:subepics) }
      condition(:contribution_analytics_available) do
        @subject.feature_available?(:contribution_analytics)
      end

      condition(:cycle_analytics_available) do
        @subject.feature_available?(:cycle_analytics_for_groups)
      end

      condition(:group_activity_analytics_available) do
        @subject.beta_feature_available?(:group_activity_analytics)
      end

      condition(:can_owners_manage_ldap, scope: :global) do
        ::Gitlab::CurrentSettings.allow_group_owners_to_manage_ldap?
      end

      condition(:memberships_locked_to_ldap, scope: :global) do
        ::Gitlab::CurrentSettings.lock_memberships_to_ldap?
      end

      condition(:owners_bypass_ldap_lock) do
        ldap_lock_bypassable?
      end

      condition(:security_dashboard_enabled) do
        @subject.feature_available?(:security_dashboard)
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

      condition(:cluster_deployments_available) do
        @subject.feature_available?(:cluster_deployments)
      end

      condition(:group_saml_enabled) do
        @subject.saml_provider&.enabled?
      end

      condition(:group_timelogs_available) do
        @subject.feature_available?(:group_timelogs)
      end

      with_scope :global
      condition(:cluster_health_available) do
        License.feature_available?(:cluster_health)
      end

      rule { public_group | logged_in_viewable }.policy do
        enable :read_wiki
        enable :download_wiki_code
      end

      rule { guest }.enable :read_wiki

      rule { reporter }.policy do
        enable :admin_list
        enable :admin_board
        enable :read_prometheus
        enable :view_productivity_analytics
        enable :view_type_of_work_charts
        enable :read_group_timelogs
        enable :download_wiki_code
      end

      rule { maintainer }.policy do
        enable :create_jira_connect_subscription
        enable :maintainer_access
        enable :admin_wiki
      end

      rule { owner }.policy do
        enable :owner_access
      end

      rule { can?(:read_cluster) & cluster_deployments_available }
        .enable :read_cluster_environments

      rule { has_access & contribution_analytics_available }
        .enable :read_group_contribution_analytics

      rule { has_access & group_activity_analytics_available }
        .enable :read_group_activity_analytics

      rule { reporter & cycle_analytics_available }.policy do
        enable :read_group_cycle_analytics, :create_group_stage, :read_group_stage, :update_group_stage, :delete_group_stage
      end

      rule { can?(:read_group) & dependency_proxy_available }
        .enable :read_dependency_proxy

      rule { developer & dependency_proxy_available }
        .enable :admin_dependency_proxy

      rule { can?(:read_group) & epics_available }.enable :read_epic

      rule { can?(:read_group) & iterations_available }.enable :read_iteration

      rule { developer & iterations_available }.policy do
        enable :create_iteration
        enable :admin_iteration
      end

      rule { reporter & epics_available }.policy do
        enable :create_epic
        enable :admin_epic
        enable :update_epic
      end

      rule { reporter & subepics_available }.policy do
        enable :admin_epic_link
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

      rule { auditor }.policy do
        enable :read_group
        enable :read_group_security_dashboard
      end

      rule { admin | owner }.enable :admin_group_saml

      rule { admin | (can_owners_manage_ldap & owner) }.policy do
        enable :admin_ldap_group_links
        enable :admin_ldap_group_settings
      end

      rule { ldap_synced & ~owners_bypass_ldap_lock }.prevent :admin_group_member

      rule { ldap_synced & (admin | owner) }.enable :update_group_member

      rule { ldap_synced & (admin | (can_owners_manage_ldap & owner)) }.enable :override_group_member

      rule { memberships_locked_to_ldap & ~admin & ~owners_bypass_ldap_lock }.policy do
        prevent :admin_group_member
        prevent :update_group_member
        prevent :override_group_member
      end

      rule { developer }.policy do
        enable :create_wiki
        enable :admin_merge_request
      end

      rule { security_dashboard_enabled & developer }.enable :read_group_security_dashboard

      rule { admin | owner }.policy do
        enable :read_group_compliance_dashboard
        enable :read_group_credentials_inventory
      end

      rule { needs_new_sso_session }.policy do
        prevent :read_group
      end

      rule { ip_enforcement_prevents_access & ~owner }.policy do
        prevent :read_group
      end

      rule { owner & group_saml_enabled }.policy do
        enable :read_group_saml_identity
      end

      rule { ~group_timelogs_available }.prevent :read_group_timelogs

      rule { can?(:read_cluster) & cluster_health_available }.enable :read_cluster_health

      rule { ~(admin | allow_to_manage_default_branch_protection) }.policy do
        prevent :update_default_branch_protection
      end

      desc "Group has wiki disabled"
      condition(:wiki_disabled, score: 32) { !feature_available?(:wiki) }

      rule { wiki_disabled }.policy do
        prevent(*create_read_update_admin_destroy(:wiki))
        prevent(:download_wiki_code)
      end
    end

    override :lookup_access_level!
    def lookup_access_level!
      return ::GroupMember::NO_ACCESS if needs_new_sso_session?

      super
    end

    # TODO: Extract this into a helper shared with ProjectPolicy, once we implement group-level features.
    # https://gitlab.com/gitlab-org/gitlab/-/issues/208412
    def feature_available?(feature)
      return false unless feature == :wiki

      case subject.wiki_access_level
      when ::ProjectFeature::DISABLED
        false
      when ::ProjectFeature::PRIVATE
        admin? || access_level >= ::ProjectFeature.required_minimum_access_level(feature)
      else
        true
      end
    end

    def ldap_lock_bypassable?
      return false unless ::Feature.enabled?(:ldap_settings_unlock_groups_by_owners)
      return false unless ::Gitlab::CurrentSettings.allow_group_owners_to_manage_ldap?

      !!subject.unlock_membership_to_ldap? && subject.owned_by?(user)
    end

    def sso_enforcement_prevents_access?
      return false unless subject.persisted?
      return false if user&.admin?

      ::Gitlab::Auth::GroupSaml::SsoEnforcer.group_access_restricted?(subject)
    end
  end
end
