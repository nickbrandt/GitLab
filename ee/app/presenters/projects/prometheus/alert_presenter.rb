# frozen_string_literal: true

module Projects
  module Prometheus
    class AlertPresenter < Gitlab::View::Presenter::Delegated
      def full_title
        [environment_name, alert_title].compact.join(': ')
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

      def starts_at
        super&.rfc3339
      end

      def issue_summary_markdown
        <<~MARKDOWN.chomp
          ## Summary

          #{metadata_list}
          #{annotation_list}
        MARKDOWN
      end

      private

      def alert_title
        query_title || title
      end

      def query_title
        return unless gitlab_alert

        "#{gitlab_alert.title} #{gitlab_alert.computed_operator} #{gitlab_alert.threshold} for 5 minutes"
      end

      def metadata_list
        metadata = []

        metadata << bullet('starts_at', starts_at) if starts_at
        metadata << bullet('full_query', backtick(full_query)) if full_query

        metadata.join("\n")
      end

      def annotation_list
        strong_memoize(:annotation_list) do
          annotations
            .map { |annotation| bullet(annotation.label, annotation.value) }
            .join("\n")
        end
      end

      def bullet(key, value)
        "* #{key}: #{value}"
      end

      def backtick(value)
        "`#{value}`"
      end
    end
  end
end
