# frozen_string_literal: true

class Groups::Security::VulnerabilitiesController < Groups::Security::ApplicationController
  HISTORY_RANGE = 3.months

  def index
    vulnerabilities = found_vulnerabilities.ordered.page(params[:page])

    respond_to do |format|
      format.json do
        render json: Vulnerabilities::OccurrenceSerializer
          .new(current_user: @current_user)
          .with_pagination(request, response)
          .represent(vulnerabilities, preload: true)
      end
    end
  end

  def summary
    vulnerabilities_summary = found_vulnerabilities.counted_by_severity

    respond_to do |format|
      format.json do
        render json: VulnerabilitySummarySerializer.new.represent(vulnerabilities_summary)
      end
    end
  end

  def history
    vulnerabilities_counter = found_vulnerabilities(:all).count_by_day_and_severity(HISTORY_RANGE)

    respond_to do |format|
      format.json do
        render json: Vulnerabilities::HistorySerializer.new.represent(vulnerabilities_counter)
      end
    end
  end

  private

  def filter_params
    params.permit(report_type: [], project_id: [], severity: [])
      .merge(hide_dismissed: Gitlab::Utils.to_boolean(params[:hide_dismissed]))
  end

  def found_vulnerabilities(collection = :latest)
    ::Security::VulnerabilitiesFinder.new(group: group, params: filter_params).execute(collection)
  end
end
