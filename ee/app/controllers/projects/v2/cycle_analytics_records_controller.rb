# frozen_string_literal: true

class Projects::V2::CycleAnalyticsRecordsController < Projects::ApplicationController
  skip_before_action :verify_authenticity_token

  def index
    stage = ::CycleAnalytics::StageFindService.new(parent: project, id: allowed_params[:stage_id]).execute
    data_collector = Gitlab::CycleAnalytics::DataCollector.new(stage, from: allowed_params[:start_date], current_user: current_user)

    render json: data_collector.records_fetcher.serialized_records
  end

  private

  def allowed_params
    params.permit(:stage_id, :start_date)
  end
end
