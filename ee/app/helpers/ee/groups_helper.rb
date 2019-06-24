# frozen_string_literal: true

module EE
  module GroupsHelper
    extend ::Gitlab::Utils::Override

    override :group_overview_nav_link_paths
    def group_overview_nav_link_paths
      super + %w[
        groups/security/dashboard#show
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

    def group_packages_nav_link_paths
      %w[
        groups/packages#index
        groups/dependency_proxies#show
      ]
    end

    def group_packages_nav?
      group_packages_list_nav? ||
        group_dependency_proxy_nav?
    end

    def group_packages_list_nav?
      @group.packages_feature_available?
    end

    def group_dependency_proxy_nav?
      @group.dependency_proxy_feature_available?
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
