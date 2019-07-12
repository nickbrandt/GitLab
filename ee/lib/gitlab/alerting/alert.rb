# frozen_string_literal: true

module Gitlab
  module Alerting
    class Alert
      include ActiveModel::Model
      include Gitlab::Utils::StrongMemoize
      include Presentable

      attr_accessor :project, :payload

      def gitlab_alert
        strong_memoize(:gitlab_alert) do
          parse_gitlab_alert_from_payload
        end
      end

      def title
        strong_memoize(:title) do
          gitlab_alert&.title || parse_title_from_payload
        end
      end

      def description
        strong_memoize(:description) do
          parse_description_from_payload
        end
      end

      def environment
        gitlab_alert&.environment
      end

      def annotations
        strong_memoize(:annotations) do
          parse_annotations_from_payload || []
        end
      end

      def starts_at
        strong_memoize(:starts_at) do
          parse_datetime_from_payload('startsAt')
        end
      end

      def full_query
        strong_memoize(:full_query) do
          gitlab_alert&.full_query || parse_expr_from_payload
        end
      end

      def valid?
        project && title && starts_at
      end

      def present
        super(presenter_class: Projects::Prometheus::AlertPresenter)
      end

      private

      def parse_gitlab_alert_from_payload
        metric_id = payload&.dig('labels', 'gitlab_alert_id')
        return unless metric_id

        Projects::Prometheus::AlertsFinder
          .new(project: project, metric: metric_id)
          .execute
          .first
      end

      def parse_title_from_payload
        payload&.dig('annotations', 'title') ||
          payload&.dig('annotations', 'summary') ||
          payload&.dig('labels', 'alertname')
      end

      def parse_description_from_payload
        payload&.dig('annotations', 'description')
      end

      def parse_annotations_from_payload
        payload&.dig('annotations')&.map do |label, value|
          Alerting::AlertAnnotation.new(label: label, value: value)
        end
      end

      def parse_datetime_from_payload(field)
        value = payload&.dig(field)
        return unless value

        Time.rfc3339(value)
      rescue ArgumentError
      end

      # Parses `g0.expr` from `generatorURL`.
      #
      # Example: http://localhost:9090/graph?g0.expr=vector%281%29&g0.tab=1
      def parse_expr_from_payload
        url = payload&.dig('generatorURL')
        return unless url

        uri = URI(url)

        Rack::Utils.parse_query(uri.query).fetch('g0.expr')
      rescue URI::InvalidURIError, KeyError
      end
    end
  end
end
