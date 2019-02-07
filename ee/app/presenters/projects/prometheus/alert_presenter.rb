# frozen_string_literal: true

module Projects
  module Prometheus
    class AlertPresenter < Gitlab::View::Presenter::Delegated
      def email_subject
        [environment_name, query_title].compact.join(' ')
      end

      def project_full_path
        project.full_path
      end

      def metric_query
        gitlab_alert&.full_query
      end

      def environment_name
        environment&.name
      end

      def performance_dashboard_link
        if environment
          metrics_project_environment_url(project, environment)
        else
          metrics_project_environments_url(project)
        end
      end

      private

      def query_title
        return unless gitlab_alert

        "#{gitlab_alert.title} #{gitlab_alert.computed_operator} #{gitlab_alert.threshold} for 5 minutes"
      end
    end
  end
end
