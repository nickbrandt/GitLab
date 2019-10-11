# frozen_string_literal: true

class Analytics::TasksByTypeController < Analytics::ApplicationController
  check_feature_flag Gitlab::Analytics::TASKS_BY_TYPE_CHART_FEATURE_FLAG

  before_action :load_group
  before_action -> { check_feature_availability!(:type_of_work_analytics) }
  before_action -> { authorize_view_by_action!(:view_type_of_work_charts) }
  before_action :validate_label_ids
  before_action :prepare_date_range

  # Mocked data, this will be replaced with real implementation
  class TasksByType
    LabelCountResult = Struct.new(:label, :series)

    def counts_by_labels
      [
        LabelCountResult.new(GroupLabel.new(id: 1, title: 'label 1'), [
          ["2018-01-01", 23],
          ["2018-01-02", 5]
        ]),
        LabelCountResult.new(GroupLabel.new(id: 2, title: 'label 3'), [
          ["2018-01-01", 3],
          ["2018-01-03", 10]
        ])
      ]
    end
  end

  def show
    render json: Analytics::TasksByTypeLabelEntity.represent(counts_by_labels)
  end

  private

  def counts_by_labels
    TasksByType.new.counts_by_labels
  end

  def validate_label_ids
    return respond_422 if Array(params[:label_ids]).empty?
  end

  def prepare_date_range
    @created_after = parse_date(params[:created_after])
    return respond_422 unless @created_after

    @created_before = parse_date(params[:created_before]) || Date.today

    return respond_422 if @created_after > @created_before
  end

  def parse_date(value)
    return unless value

    Date.parse(value)
  rescue ArgumentError
  end
end
