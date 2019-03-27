# frozen_string_literal: true

module InsightsActions
  extend ActiveSupport::Concern

  included do
    before_action :check_insights_available!
    before_action :validate_params, only: [:query]
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
    issuables = find_issuables(params[:query])
    insights = reduce(issuables, params[:chart_type], params[:query])
    serializer(params[:chart_type]).present(insights)
  end

  def find_issuables(query)
    Gitlab::Insights::Finders::IssuableFinder
      .new(insights_entity, current_user, query).find
  end

  def reduce(issuables, chart_type, query)
    case chart_type
    when 'stacked-bar', 'line'
      Gitlab::Insights::Reducers::LabelCountPerPeriodReducer.reduce(issuables, period: query[:group_by], labels: query[:collection_labels])
    when 'bar'
      Gitlab::Insights::Reducers::CountPerPeriodReducer.reduce(issuables, period: query[:group_by])
    end
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
end
