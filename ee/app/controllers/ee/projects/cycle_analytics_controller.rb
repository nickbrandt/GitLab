# frozen_string_literal: true

module EE
  module Projects
    module CycleAnalyticsController
      extend ActiveSupport::Concern

      prepended do
        before_action :authorize_cycle_analytics_duration_chart, only: [:duration_chart]
      end

      def duration_chart
        stage_class = ::Gitlab::CycleAnalytics::Stage[params[:stage_id]]
        stage = stage_class.new(options: options(cycle_analytics_params).merge(project: project))

        render json: stage.data_for_duration_chart
      end

      private

      def authorize_cycle_analytics_duration_chart
        unless can?(current_user, :read_project_cycle_analytics_duration_chart, project)
          render_403
        end
      end
    end
  end
end
