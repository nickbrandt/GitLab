# frozen_string_literal: true

module EE
  module Projects
    module CycleAnalyticsController
      extend ActiveSupport::Concern

      prepended do
        include CycleAnalytics::DurationChart
        before_action :authorize_cycle_analytics_duration_chart, only: [:duration_chart]
      end

      private

      def duration_chart_params
        options(cycle_analytics_params).merge(project: project)
      end

      def authorize_cycle_analytics_duration_chart
        unless can?(current_user, :read_project_cycle_analytics_duration_chart, project)
          render_403
        end
      end
    end
  end
end
