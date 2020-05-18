# frozen_string_literal: true

module AlertManagement
  class UpdateAlertStatusService
    include Gitlab::Utils::StrongMemoize

    # @param alert [AlertManagement::Alert]
    # @param user [User]
    # @param status [Integer] Must match a value from AlertManagement::Alert::STATUSES
    def initialize(alert, user, params)
      @alert = alert
      @user = user
      @status = params.fetch(:status)
      @ended_at = params[:ended_at]
    end

    def execute
      return error_no_permissions unless allowed?
      return error_invalid_status unless status_key

      if change_status_to(status: status, ended_at: ended_at)
        success
      else
        error(alert.errors.full_messages.to_sentence)
      end
    end

    private

    def change_status_to(status:, ended_at: nil)
      case status
      when AlertManagement::Alert::STATUSES[:triggered]
        alert.trigger
      when AlertManagement::Alert::STATUSES[:acknowledged]
        alert.acknowledge
      when AlertManagement::Alert::STATUSES[:resolved]
        alert.resolve(ended_at)
      when AlertManagement::Alert::STATUSES[:ignored]
        alert.ignore
      end
    end

    attr_reader :alert, :user, :status, :ended_at

    delegate :project, to: :alert

    def allowed?
      user.can?(:update_alert_management_alert, project)
    end

    def status_key
      strong_memoize(:status_key) do
        AlertManagement::Alert::STATUSES.key(status)
      end
    end

    def success
      ServiceResponse.success(payload: { alert: alert })
    end

    def error_no_permissions
      error(_('You have no permissions'))
    end

    def error_invalid_status
      error(_('Invalid status'))
    end

    def error(message)
      ServiceResponse.error(payload: { alert: alert }, message: message)
    end
  end
end
