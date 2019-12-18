# frozen_string_literal: true

module ErrorTracking
  class ProjectSettingsService < ErrorTracking::BaseService

    private

    def fetch
      project_error_tracking_setting.sentry_project_settings
    end
  end
end