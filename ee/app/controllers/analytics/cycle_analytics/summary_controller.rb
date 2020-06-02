# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    class SummaryController < Analytics::ApplicationController
      include CycleAnalyticsParams

      check_feature_flag Gitlab::Analytics::CYCLE_ANALYTICS_FEATURE_FLAG

      before_action :load_group
      before_action :authorize_access
      before_action :validate_params

      def show
        render json: group_level.summary
      end

      def time_summary
        render json: group_level.time_summary
      end

      private

      def group_level
        @group_level ||= GroupLevel.new(group: @group, options: options(request_params.to_data_collector_params))
      end

      def validate_params
        if request_params.invalid?
          render(
            json: { message: 'Invalid parameters', errors: request_params.errors },
            status: :unprocessable_entity
          )
        end
      end

      def request_params
        @request_params ||= Gitlab::Analytics::CycleAnalytics::RequestParams.new(allowed_params.merge(current_user: current_user))
      end

      def allowed_params
        params.permit(*Gitlab::Analytics::CycleAnalytics::RequestParams::STRONG_PARAMS_DEFINITION)
      end

      def authorize_access
        return render_403 unless can?(current_user, :read_group_cycle_analytics, @group)
      end
    end
  end
end
