# frozen_string_literal: true

class Analytics::CodeAnalyticsController < Analytics::ApplicationController
  check_feature_flag Gitlab::Analytics::CODE_ANALYTICS_FEATURE_FLAG

  before_action :load_group
  before_action :load_project

  before_action -> {
    check_feature_availability!(:code_analytics)
  }, if: -> { request.format.json? }

  before_action -> {
    authorize_view_by_action!(:view_code_analytics)
  }

  before_action :validate_params, if: -> { request.format.json? }

  def show
    respond_to do |format|
      format.html
      format.json { render json: Analytics::CodeAnalytics::RepositoryFileCommitCountEntity.represent(top_files) }
    end
  end

  private

  def validate_params
    render(json: { message: 'Invalid parameters', errors: request_params.errors }, status: :unprocessable_entity) if request_params.invalid?
  end

  def request_params
    @request_params ||= Gitlab::Analytics::CodeAnalytics::RequestParams.new(allowed_params)
  end

  def top_files
    Analytics::CodeAnalyticsFinder.new(
      project: @project,
      file_count: request_params.file_count,
      from: request_params.from,
      to: request_params.to
    ).execute
  end

  def allowed_params
    params.permit(:file_count)
  end
end
