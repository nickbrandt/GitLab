# frozen_string_literal: true

module AlertManagement
  class AlertPresenter < Gitlab::View::Presenter::Delegated
    include Gitlab::Utils::StrongMemoize
    include IncidentManagement::Settings

    def initialize(alert, _attributes = {})
      super

      @alert = alert
      @project = alert.project
    end

    delegate :alert_markdown, :issue_summary_markdown, to: :alerting_alert

    def issue_description
      horizontal_line = "\n\n---\n\n"

      [
        issue_summary_markdown,
        alert_markdown,
        incident_management_setting.issue_template_content
      ].compact.join(horizontal_line)
    end

    private

    attr_reader :alert, :project

    def alert_payload
      if alert.prometheus?
        alert.payload
      else
        Gitlab::Alerting::NotificationPayloadParser.call(alert.payload.to_h)
      end
    end

    def alerting_alert
      strong_memoize(:alertign_alert) do
        Gitlab::Alerting::Alert.new(project: project, payload: alert_payload).present
      end
    end
  end
end
