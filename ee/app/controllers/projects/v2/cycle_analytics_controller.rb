# frozen_string_literal: true

class Projects::V2::CycleAnalyticsController < Projects::ApplicationController
  def show
    stages = ::CycleAnalytics::StageListService.new(parent: project).execute
    render json: ::CycleAnalytics::CycleAnalyticsEntity.new(stages)
  end

  def median
    stage = ::CycleAnalytics::ProjectStage.find(params[:stage_id])
    data_collector = Gitlab::CycleAnalytics::DataCollector.new(stage, from = 1.year.ago)
    render json: ::CycleAnalytics::MedianEntity.new(data_collector.median.seconds)
  end
end

