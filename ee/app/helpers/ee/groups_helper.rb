# frozen_string_literal: true

module EE
  module GroupsHelper
    extend ::Gitlab::Utils::Override

    def group_epics_count(state:)
      EpicsFinder
        .new(current_user, group_id: @group.id, state: state)
        .execute
        .count
    end

    override :group_overview_nav_link_paths
    def group_overview_nav_link_paths
      super + %w[
        groups/insights#show
      ]
    end

    override :group_nav_link_paths
    def group_nav_link_paths
      if ::Gitlab::CurrentSettings.should_check_namespace_plan? && can?(current_user, :admin_group, @group)
        super + %w[billings#index saml_providers#show]
      else
        super
      end
    end

    def size_limit_message_for_group(group)
      show_lfs = group.lfs_enabled? ? 'and their respective LFS files' : ''

      "Repositories within this group #{show_lfs} will be restricted to this maximum size. Can be overridden inside each project. 0 for unlimited. Leave empty to inherit the global value."
    end

    override :group_packages_nav_link_paths
    def group_packages_nav_link_paths
      %w[
        groups/packages#index
        groups/dependency_proxies#show
        groups/container_registries#index
      ]
    end

    def group_packages_nav?
      group_packages_list_nav? ||
        group_dependency_proxy_nav? ||
        group_container_registry_nav?
    end

    def group_packages_list_nav?
      @group.packages_feature_available?
    end

    def group_dependency_proxy_nav?
      @group.dependency_proxy_feature_available?
    end

    def group_path_params(group)
      { group_id: group }
    end

    def group_vulnerabilities_endpoint_path(group)
      params = group_path_params(group)
      if ::Feature.enabled?(:first_class_vulnerabilities)
        group_security_vulnerability_findings_path(params)
      else
        group_security_vulnerabilities_path(params)
      end
    end

    def group_vulnerabilities_summary_endpoint_path(group)
      params = group_path_params(group)
      if ::Feature.enabled?(:first_class_vulnerabilities)
        summary_group_security_vulnerability_findings_path(params)
      else
        summary_group_security_vulnerabilities_path(params)
      end
    end

    def group_vulnerabilities_history_endpoint_path(group)
      params = group_path_params(group)
      if ::Feature.enabled?(:first_class_vulnerabilities)
        history_group_security_vulnerability_findings_path(params)
      else
        history_group_security_vulnerabilities_path(params)
      end
    end

    private

    def get_group_sidebar_links
      links = super

      if can?(current_user, :read_group_contribution_analytics, @group) || show_promotions?
        links << :contribution_analytics
      end

      if can?(current_user, :read_epic, @group)
        links << :epics
      end

      if @group.feature_available?(:issues_analytics)
        links << :analytics
      end

      if @group.insights_available?
        links << :group_insights
      end

      links
    end
  end
end
