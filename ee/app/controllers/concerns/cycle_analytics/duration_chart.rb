# frozen_string_literal: true

module CycleAnalytics
  module DurationChart
    extend ActiveSupport::Concern

    def duration_chart
      stage_class = ::Gitlab::CycleAnalytics::Stage[params[:stage_name]]
      stage = stage_class.new(options: duration_chart_params)

      render json: stage.data_for_duration_chart

    rescue NameError
      respond_422
    end
  end
end
