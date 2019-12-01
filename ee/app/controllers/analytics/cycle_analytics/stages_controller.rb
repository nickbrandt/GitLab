# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    class StagesController < Analytics::ApplicationController
      check_feature_flag Gitlab::Analytics::CYCLE_ANALYTICS_FEATURE_FLAG

      before_action :load_group
      before_action :validate_params, only: %i[median records duration_chart]

      def index
        return render_403 unless can?(current_user, :read_group_cycle_analytics, @group)

        result = list_service.execute

        if result.success?
          render json: cycle_analytics_configuration(result.payload[:stages])
        else
          render json: { message: result.message }, status: result.http_status
        end
      end

      def create
        return render_403 unless can?(current_user, :create_group_stage, @group)

        render_stage_service_result(create_service.execute)
      end

      def update
        return render_403 unless can?(current_user, :update_group_stage, @group)

        render_stage_service_result(update_service.execute)
      end

      def destroy
        return render_403 unless can?(current_user, :delete_group_stage, @group)

        render_stage_service_result(delete_service.execute)
      end

      def median
        return render_403 unless can?(current_user, :read_group_stage, @group)

        render json: { value: data_collector.median.seconds }
      end

      def records
        return render_403 unless can?(current_user, :read_group_stage, @group)

        render json: data_collector.serialized_records
      end

      def duration_chart
        return render_403 unless can?(current_user, :read_group_stage, @group)

        render json: Analytics::CycleAnalytics::DurationChartItemEntity.represent(data_collector.duration_chart_data)
      end

      private

      def validate_params
        if request_params.invalid?
          render(
            json: { message: 'Invalid parameters', errors: request_params.errors },
            status: :unprocessable_entity
          )
        end
      end

      def request_params
        @request_params ||= Gitlab::Analytics::CycleAnalytics::RequestParams.new(data_collector_params)
      end

      def data_collector
        @data_collector ||= Gitlab::Analytics::CycleAnalytics::DataCollector.new(stage: stage, params: {
          current_user: current_user,
          from: request_params.created_after,
          to: request_params.created_before,
          project_ids: request_params.project_ids
        })
      end

      def stage
        @stage ||= Analytics::CycleAnalytics::StageFinder.new(parent: @group, stage_id: params[:id]).execute
      end

      def cycle_analytics_configuration(stages)
        stage_presenters = stages.map { |s| StagePresenter.new(s) }

        Analytics::CycleAnalytics::ConfigurationEntity.new(stages: stage_presenters)
      end

      def list_service
        Stages::ListService.new(parent: @group, current_user: current_user)
      end

      def create_service
        Stages::CreateService.new(parent: @group, current_user: current_user, params: create_params)
      end

      def update_service
        Stages::UpdateService.new(parent: @group, current_user: current_user, params: update_params)
      end

      def delete_service
        Stages::DeleteService.new(parent: @group, current_user: current_user, params: delete_params)
      end

      def render_stage_service_result(result)
        if result.success?
          stage = StagePresenter.new(result.payload[:stage])
          render json: Analytics::CycleAnalytics::StageEntity.new(stage), status: result.http_status
        else
          render json: { message: result.message, errors: result.payload[:errors] }, status: result.http_status
        end
      end

      def data_collector_params
        params.permit(:created_before, :created_after, project_ids: [])
      end

      def update_params
        params.permit(:name, :start_event_identifier, :end_event_identifier, :id, :move_after_id, :move_before_id, :hidden)
      end

      def create_params
        params.permit(:name, :start_event_identifier, :end_event_identifier)
      end

      def delete_params
        params.permit(:id)
      end
    end
  end
end
