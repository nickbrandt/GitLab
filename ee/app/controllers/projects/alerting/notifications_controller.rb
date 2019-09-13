# frozen_string_literal: true

module Projects
  module Alerting
    class NotificationsController < Projects::ApplicationController
      respond_to :json

      skip_before_action :project

      prepend_before_action :repository, :project_without_auth
      before_action :check_generic_alert_endpoint_feature_flag!

      def create
        token = extract_alert_manager_token(request)
        result = notify_service.execute(token)

        head(response_status(result))
      end

      private

      PARAMS_TO_EXCLUDE = %w(controller action namespace_id project_id).freeze

      def project_without_auth
        @project ||= Project
          .find_by_full_path("#{params[:namespace_id]}/#{params[:project_id]}")
      end

      def check_generic_alert_endpoint_feature_flag!
        render_404 unless Feature.enabled?(:generic_alert_endpoint, @project)
      end

      def extract_alert_manager_token(request)
        Doorkeeper::OAuth::Token.from_bearer_authorization(request)
      end

      def notify_service
        Projects::Alerting::NotifyService
          .new(project, current_user, permitted_params)
      end

      def response_status(result)
        case result.http_status
        when 401
          :unauthorized
        when 403
          :forbidden
        else
          :ok
        end
      end

      def permitted_params
        params.except(*PARAMS_TO_EXCLUDE).permit! # rubocop:disable CodeReuse/ActiveRecord
      end
    end
  end
end
