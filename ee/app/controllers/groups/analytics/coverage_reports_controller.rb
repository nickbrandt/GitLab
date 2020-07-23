# frozen_string_literal: true

class Groups::Analytics::CoverageReportsController < Groups::Analytics::ApplicationController
  check_feature_flag Gitlab::Analytics::CYCLE_ANALYTICS_FEATURE_FLAG

  before_action :load_group
  before_action -> { check_feature_availability!(:group_coverage_reports) }

  def index
    respond_to do |format|
      format.csv { send_data([].to_csv, type: 'text/csv; charset=utf-8') }
    end
  end
end
