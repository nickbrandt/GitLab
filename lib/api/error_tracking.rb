# frozen_string_literal: true

module API
  class ErrorTracking < Grape::API
    before { authenticate! }

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end

    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Get sentry error tracking settings for the project' do
        success Entities::SentryProjectErrorTrackingSettings
      end

      get ':id/error_tracking/sentry_project_settings' do
        authorize! :read_sentry_issue, user_project

        setting = user_project.error_tracking_setting

        not_found!('Error Tracking Setting') unless setting

        present setting, with: Entities::SentryProjectErrorTrackingSettings
      end
    end
  end
end
