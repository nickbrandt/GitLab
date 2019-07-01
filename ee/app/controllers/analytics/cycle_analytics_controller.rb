# frozen_string_literal: true

class Analytics::CycleAnalyticsController < Analytics::ApplicationController
  def show
    respond_to do |format|
      format.html
    end
  end
end
