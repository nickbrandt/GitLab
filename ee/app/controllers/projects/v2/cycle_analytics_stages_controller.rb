# frozen_string_literal: true

class Projects::V2::CycleAnalyticsStagesController < Projects::ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    stage = ::CycleAnalytics::StageCreateService.new(parent: project, params: allowed_params).execute

    if stage.valid?
      render json: ::CycleAnalytics::StageEntity.new(stage), status: :created
    else
      render json: { message: stage.errors.messages }, status: :unprocessable_entity
    end
  end

  def update
    stage = ::CycleAnalytics::StageFindService.new(parent: project, id: params[:id]).execute
    stage = ::CycleAnalytics::StageUpdateService.new(stage: stage, params: allowed_params).execute

    if stage.valid?
      render json: ::CycleAnalytics::StageEntity.new(stage)
    else
      render json: { message: stage.errors.messages }, status: :unprocessable_entity
    end
  end

  def destroy
    stage = ::CycleAnalytics::StageFindService.new(parent: project, id: params[:id]).execute
    stage.destroy

    head :ok
  end

  private

  def allowed_params
    params.permit(:name, :hidden, start_event: [:identifier, :label_id], end_event: [:identifier, :label_id])
  end
end
