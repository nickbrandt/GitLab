# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    class StagesController < Analytics::ApplicationController
      check_feature_flag Gitlab::Analytics::CYCLE_ANALYTICS_FEATURE_FLAG

      before_action :load_group
      before_action :authorize_access!

      def index
        result = stage_list_service.execute

        if result.success?
          render json: cycle_analytics_configuration(result.payload[:stages])
        else
          render json: { message: result.message }, status: result.http_status
        end
      end

      private

      def authorize_access!
        render_403 unless can?(current_user, :read_group_cycle_analytics, @group)
      end

      def cycle_analytics_configuration(stages)
        stage_presenters = stages.map { |s| StagePresenter.new(s) }

        Analytics::CycleAnalytics::ConfigurationEntity.new(stages: stage_presenters)
      end

      def stage_list_service
        Analytics::CycleAnalytics::Stages::ListService.new(
          parent: @group,
          current_user: current_user
        )
      end
    end
  end
end
