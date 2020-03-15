# frozen_string_literal: true

module AnalyticsNavbarHelper
  class NavbarSubItem
    attr_reader :title, :path, :link, :link_to_options

    def initialize(title:, path:, link:, link_to_options: {})
      @title = title
      @path = path
      @link = link
      @link_to_options = link_to_options.merge(title: title)
    end
  end

  def project_analytics_navbar_links(project, current_user)
    [
      cycle_analytics_navbar_link(project, current_user, 0),
      repository_analytics_navbar_link(project, current_user, 3),
      ci_cd_analytics_navbar_link(project, current_user, 5)
    ].compact
  end

  def group_analytics_navbar_links(group, current_user)
    []
  end

  private

  def navbar_sub_item(args)
    NavbarSubItem.new(args)
  end

  def cycle_analytics_navbar_link(project, current_user, index = 0)
    return unless project_nav_tab?(:cycle_analytics)

    navbar_sub_item(
      title: _('Value Stream'),
      path: 'cycle_analytics#show',
      link: project_cycle_analytics_path(project),
      link_to_options: { class: 'shortcuts-project-cycle-analytics', data: { index: index } }
    )
  end

  def repository_analytics_navbar_link(project, current_user, index = 0)
    return if project.empty_repo?

    navbar_sub_item(
      title: _('Repository'),
      path: 'graphs#charts',
      link: charts_project_graph_path(project, current_ref),
      link_to_options: { class: 'shortcuts-repository-charts', data: { index: index } }
    )
  end

  def ci_cd_analytics_navbar_link(project, current_user, index = 0)
    return unless project_nav_tab?(:pipelines)
    return unless project.feature_available?(:builds, current_user) || !project.empty_repo?

    navbar_sub_item(
      title: _('CI / CD'),
      path: 'pipelines#charts',
      link: charts_project_pipelines_path(project),
      link_to_options: { data: { index: index } }
    )
  end
end

AnalyticsNavbarHelper.prepend_if_ee('EE::AnalyticsNavbarHelper')
