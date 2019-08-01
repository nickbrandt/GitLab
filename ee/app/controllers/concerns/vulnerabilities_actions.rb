# frozen_string_literal: true

# The VulnerabilitiesActions concern contains actions that are used to populate vulnerabilities
# on security dashboards.
#
# Note: Consumers of this module will need to define a `def vulnerable` method, which must return
# an object with an interface that matches the one provided by the Vulnerable model concern.

module VulnerabilitiesActions
  extend ActiveSupport::Concern

  def index
    vulnerabilities = found_vulnerabilities(:with_sha).ordered.page(params[:page])

    respond_to do |format|
      format.json do
        render json: Vulnerabilities::OccurrenceSerializer
          .new(current_user: current_user)
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
    history_count = Gitlab::Vulnerabilities::History.new(group, filter_params).vulnerabilities_counter

    respond_to do |format|
      format.json do
        render json: history_count
      end
    end
  end

  private

  def filter_params
    params.permit(report_type: [], confidence: [], project_id: [], severity: [])
      .merge(hide_dismissed: ::Gitlab::Utils.to_boolean(params[:hide_dismissed]))
  end

  def found_vulnerabilities(collection = :latest)
    ::Security::VulnerabilitiesFinder.new(vulnerable, params: filter_params).execute(collection)
  end
end
