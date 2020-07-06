# frozen_string_literal: true

module Projects
  module Metrics
    class DashboardController < Projects::ApplicationController
      include MetricsDashboard

      before_action :environment

      def index
        respond_to do |format|
          format.html
          format.json do
            # Currently, this acts as a hint to load the metrics details into the cache
            # if they aren't there already
            @metrics = environment.metrics || {}

            render json: @metrics, status: @metrics.any? ? :ok : :no_content
          end
        end
      end

      private

      def environment
        if params[:env_id]
          @environment ||= project.environments.find(params[:env_id])
        end
      end
    end
  end
end
