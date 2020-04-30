# frozen_string_literal: true

module AlertManagement
  class UpdateAlertStatusService
    def initialize(alert, status)
      @alert = alert
      @status = status
    end

    def execute!
      return error_response('Invalid status') unless AlertManagement::Alert.statuses.key?(status.to_s)

      alert.status = status

      return ServiceResponse.success(payload: { alert: alert }) if alert.save

      error_response
    end

    private

    def error_response(message)
      ServiceResponse.error(payload: { alert: alert }, message: message)
    end

    attr_reader :alert, :status
  end
end
