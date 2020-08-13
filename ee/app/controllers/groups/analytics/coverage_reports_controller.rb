# frozen_string_literal: true

class Groups::Analytics::CoverageReportsController < Groups::Analytics::ApplicationController
  check_feature_flag Gitlab::Analytics::CYCLE_ANALYTICS_FEATURE_FLAG

  COVERAGE_PARAM = 'coverage'.freeze

  before_action :load_group
  before_action -> { check_feature_availability!(:group_coverage_reports) }

  def index
    respond_to do |format|
      format.csv { send_data(render_csv(report_results), type: 'text/csv; charset=utf-8') }
    end
  end

  private

  def render_csv(collection)
    CsvBuilders::SingleBatch.new(
      collection,
      {
        date: 'date',
        group_name: 'group_name',
        project_name: -> (record) { record.project.name },
        COVERAGE_PARAM => -> (record) { record.data[COVERAGE_PARAM] }
      }
    ).render
  end

  def report_results
    Ci::DailyBuildGroupReportResultsByGroupFinder.new(finder_params).execute
  end

  def finder_params
    {
      current_user: current_user,
      group: @group,
      ref_path: params.require(:ref_path),
      start_date: Date.parse(params.require(:start_date)),
      end_date: Date.parse(params.require(:end_date))
    }
  end
end
