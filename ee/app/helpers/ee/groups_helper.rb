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
      if ::Feature.enabled?(:analytics_pages_under_group_analytics_sidebar, @group)
        super
      else
        super + %w[
          groups/insights#show
        ]
      end
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

    override :remove_group_message
    def remove_group_message(group)
      return super unless group.feature_available?(:adjourned_deletion_for_projects_and_groups)

      date = permanent_deletion_date(Time.now.utc)

      _("The contents of this group, its subgroups and projects will be permanently removed after %{deletion_adjourned_period} days on %{date}. After this point, your data cannot be recovered.") %
        { date: date, deletion_adjourned_period: deletion_adjourned_period }
    end

    def permanent_deletion_date(date)
      (date + deletion_adjourned_period.days).strftime('%F')
    end

    def deletion_adjourned_period
      ::Gitlab::CurrentSettings.deletion_adjourned_period
    end

    def show_discover_group_security?(group)
      !!::Feature.enabled?(:discover_security) &&
        ::Gitlab.com? &&
        !!current_user &&
        current_user.created_at > DateTime.new(2020, 1, 20) &&
        !@group.feature_available?(:security_dashboard) &&
        can?(current_user, :admin_group, @group)
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

      if @group.feature_available?(:productivity_analytics) && can?(current_user, :view_productivity_analytics, @group)
        links << :productivity_analytics
      end

      links
    end
  end
end
