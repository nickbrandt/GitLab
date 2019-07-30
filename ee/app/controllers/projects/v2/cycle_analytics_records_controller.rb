# frozen_string_literal: true

class Projects::V2::CycleAnalyticsRecordsController < Projects::ApplicationController
  skip_before_action :verify_authenticity_token

  def index
    stage = ::CycleAnalytics::StageFindService.new(parent: project, id: params[:id]).execute
    data_collector = Gitlab::CycleAnalytics::DataCollector.new(stage, from = 1.year.ago)

    render json: ::CycleAnalytics::MedianEntity.new(data_collector.median.seconds)
  end
end

