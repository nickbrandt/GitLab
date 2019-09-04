# frozen_string_literal: true

module Projects
  module Alerting
    class NotificationsController < Projects::ApplicationController
      respond_to :json

      skip_before_action :project

      prepend_before_action :repository, :project_without_auth
      before_action :check_generic_alert_endpoint_feature_flag!

      def create
        head :ok
      end

      private

      def project_without_auth
        @project ||= Project
          .find_by_full_path("#{params[:namespace_id]}/#{params[:project_id]}")
      end

      def check_generic_alert_endpoint_feature_flag!
        render_404 unless Feature.enabled?(:generic_alert_endpoint, @project)
      end
    end
  end
end
