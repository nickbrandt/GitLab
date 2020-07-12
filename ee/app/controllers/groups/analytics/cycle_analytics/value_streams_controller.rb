# frozen_string_literal: true

class Groups::Analytics::CycleAnalytics::ValueStreamsController < Analytics::ApplicationController
  respond_to :json

  check_feature_flag Gitlab::Analytics::CYCLE_ANALYTICS_FEATURE_FLAG

  before_action :load_group
  before_action do
    render_403 unless can?(current_user, :read_group_cycle_analytics, @group)
  end

  def index
    render json: Analytics::GroupValueStreamSerializer.new.represent(@group.value_streams)
  end

  def create
    value_stream = @group.value_streams.build(value_stream_params)

    if value_stream.save
      render json: Analytics::GroupValueStreamSerializer.new.represent(value_stream)
    else
      render json: { message: 'Invalid parameters', payload: { errors: value_stream.errors } }, status: :unprocessable_entity
    end
  end

  private

  def value_stream_params
    params.require(:value_stream).permit(:name)
  end
end
