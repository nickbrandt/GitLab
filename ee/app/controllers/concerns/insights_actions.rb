# frozen_string_literal: true

module InsightsActions
  extend ActiveSupport::Concern

  included do
    before_action :check_insights_available!
    before_action :validate_params, only: [:query]

    rescue_from Gitlab::Insights::Validators::ParamsValidator::ParamsValidatorError,
      Gitlab::Insights::Finders::IssuableFinder::IssuableFinderError, with: :render_insights_chart_error
  end

  def show
    respond_to do |format|
      format.html
      format.json do
        render json: config_data
      end
    end
  end

  def query
    respond_to do |format|
      format.json do
        render json: insights_json
      end
    end
  end

  private

  def check_insights_available!
    render_404 unless insights_entity.insights_available?
  end

  def validate_params
    Gitlab::Insights::Validators::ParamsValidator.new(params).validate!
  end

  def insights_json
    issuables_finder = finder(params[:query])
    issuables = issuables_finder.find
    insights = reduce(
      issuables: issuables,
      chart_type: params[:chart_type],
      period: params[:query][:group_by],
      period_limit: issuables_finder.period_limit,
      labels: params[:query][:collection_labels])
    serializer(params[:chart_type]).present(insights)
  end

  def reduce(issuables:, chart_type:, period:, period_limit:, labels: nil)
    case chart_type
    when 'stacked-bar', 'line'
      Gitlab::Insights::Reducers::LabelCountPerPeriodReducer.reduce(issuables, period: period, period_limit: period_limit, labels: labels)
    when 'bar'
      Gitlab::Insights::Reducers::CountPerPeriodReducer.reduce(issuables, period: period, period_limit: period_limit)
    end
  end

  def finder(query)
    Gitlab::Insights::Finders::IssuableFinder
      .new(insights_entity, current_user, query)
  end

  def serializer(chart_type)
    case chart_type
    when 'stacked-bar'
      Gitlab::Insights::Serializers::Chartjs::MultiSeriesSerializer
    when 'bar'
      Gitlab::Insights::Serializers::Chartjs::BarSerializer
    when 'line'
      Gitlab::Insights::Serializers::Chartjs::LineSerializer
    end
  end

  def config_data
    insights_entity.insights_config
  end

  def render_insights_chart_error(exception)
    render json: { message: exception.message }, status: :unprocessable_entity
  end
end
