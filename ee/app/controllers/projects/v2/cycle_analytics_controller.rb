# frozen_string_literal: true

class Projects::V2::CycleAnalyticsController < Projects::ApplicationController
  def show
    stages = ::CycleAnalytics::StageListService.new(parent: project).execute
    render json: ::CycleAnalytics::CycleAnalyticsEntity.new(stages)
  end

  def median
    stage = ::CycleAnalytics::StageFindService.new(parent: project, id: params[:stage_id]).execute
    data_collector = Gitlab::CycleAnalytics::DataCollector.new(stage, from: 1.year.ago)
    render json: ::CycleAnalytics::MedianEntity.new(data_collector.median.seconds)
  end

  def duration_chart
    stage = ::CycleAnalytics::StageFindService.new(parent: project, id: params[:stage_id]).execute
    data_collector = Gitlab::CycleAnalytics::DataCollector.new(stage, from: 1.year.ago)
    data = data_collector.with_end_date_and_duration_in_seconds.map do |row|
      [DateTime.strptime(row['finished_at'].to_s, '%s'), row['duration_in_seconds']]
    end
    render json: data
  end
end
