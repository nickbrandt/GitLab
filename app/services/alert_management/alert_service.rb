# frozen_string_literal: true

module AlertManagement
  class AlertService
    attr_reader :alert

    def initialize(alert)
      @alert = alert
    end

    def set_status!(status)
      return unless AlertManagement::Alert.statuses.key?(status.to_s)

      # rubocop:disable GitlabSecurity/PublicSend
      alert.public_send("#{status}!")
      # rubocop:enable GitlabSecurity/PublicSend
    end
  end
end
