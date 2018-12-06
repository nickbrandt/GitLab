# frozen_string_literal: true
class Groups::Security::VulnerabilitiesController < Groups::Security::ApplicationController
  HISTORY_RANGE = 3.months

  before_action :check_group_security_dashboard_history_feature_flag!, only: [:history]

  def index
    @vulnerabilities = group.latest_vulnerabilities
      .sast # FIXME: workaround until https://gitlab.com/gitlab-org/gitlab-ee/issues/6240
      .ordered
      .page(params[:page])

    respond_to do |format|
      format.json do
        render json: Vulnerabilities::OccurrenceSerializer
          .new(current_user: @current_user)
          .with_pagination(request, response)
          .represent(@vulnerabilities, preload: true)
      end
    end
  end

  def summary
    respond_to do |format|
      format.json do
        render json: VulnerabilitySummarySerializer.new.represent(group)
      end
    end
  end

  def history
    respond_to do |format|
      format.json do
        render json: Vulnerabilities::HistorySerializer.new.represent(group.all_vulnerabilities.count_by_day_and_severity(HISTORY_RANGE))
      end
    end
  end

  def check_group_security_dashboard_history_feature_flag!
    render_404 unless ::Feature.enabled?(:group_security_dashboard_history, group, default_enabled: true)
  end
end
