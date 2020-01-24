# frozen_string_literal: true

module EE
  module AnalyticsNavbarHelper
    extend ::Gitlab::Utils::Override

    override :project_analytics_navbar_links
    def project_analytics_navbar_links(project, current_user)
      super + [
        insights_navbar_link(project, current_user),
        code_review_analytics_navbar_link(project, current_user)
      ].compact
    end

    private

    def insights_navbar_link(project, current_user)
      return unless ::Feature.enabled?(:analytics_pages_under_project_analytics_sidebar, project)
      return unless project_nav_tab?(:project_insights)

      navbar_sub_item(
        title: _('Insights'),
        path: 'insights#show',
        link: project_insights_path(project),
        link_to_options: { class: 'shortcuts-project-insights', data: { qa_selector: 'project_insights_link' } }
      )
    end

    def code_review_analytics_navbar_link(project, current_user)
      return unless project_nav_tab?(:code_review)

      navbar_sub_item(
        title: _('Code Review'),
        path: 'projects/analytics/code_reviews#index',
        link: project_analytics_code_reviews_path(project)
      )
    end
  end
end
