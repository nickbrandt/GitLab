# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    class SummaryController < Analytics::ApplicationController
      include CycleAnalyticsParams

      check_feature_flag Gitlab::Analytics::CYCLE_ANALYTICS_FEATURE_FLAG

      before_action :load_group
      before_action :validate_params

      def show
        return render_403 unless can?(current_user, :read_group_cycle_analytics, @group)

        group_level = ::CycleAnalytics::GroupLevel.new(group: @group, options: options(allowed_group_params))

        render json: group_level.summary
      end

      private

      def allowed_group_params
        params.permit(:created_after, :created_before, project_ids: [])
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
        @request_params ||= Gitlab::Analytics::CycleAnalytics::RequestParams.new(params.permit(:created_before, :created_after))
      end
    end
  end
end
