# frozen_string_literal: true

# Provides an action which fetches a metrics dashboard according
# to the parameters specified by the controller.
module MetricsDashboard
  include RenderServiceResults
  include ChecksCollaboration

  extend ActiveSupport::Concern

  def metrics_dashboard
    result = dashboard_finder.find(
      project_for_dashboard,
      current_user,
      metrics_dashboard_params.to_h.symbolize_keys
    )

    if include_all_dashboards? && result
      result[:all_dashboards] = all_dashboards
    end

    respond_to do |format|
      if result.nil?
        format.json { continue_polling_response }
      elsif result[:status] == :success
        format.json { render dashboard_success_response(result) }
      else
        format.json { render dashboard_error_response(result) }
      end
    end
  end

  private

  def all_dashboards
    dashboards = dashboard_finder.find_all_paths(project_for_dashboard)
    dashboards.map do |dashboard|
      dashboard[:edit_path] = edit_path(dashboard)
      dashboard
    end
  end

  def edit_path(dashboard)
    return unless project_for_dashboard
    return if dashboard[:system_dashboard]
    return unless can_collaborate_with_project?(project_for_dashboard, ref: project_for_dashboard.default_branch)

    Gitlab::Routing.url_helpers.project_blob_path(project_for_dashboard, File.join(project_for_dashboard.default_branch, dashboard[:path]))
  end

  # Override in class to provide arguments to the finder.
  def metrics_dashboard_params
    {}
  end

  # Override in class if response requires complete list of
  # dashboards in addition to requested dashboard body.
  def include_all_dashboards?
    false
  end

  def dashboard_finder
    ::Gitlab::Metrics::Dashboard::Finder
  end

  # Project is not defined for group and admin level clusters.
  def project_for_dashboard
    defined?(project) ? project : nil
  end

  def dashboard_success_response(result)
    {
      status: :ok,
      json: result.slice(:all_dashboards, :dashboard, :status)
    }
  end

  def dashboard_error_response(result)
    {
      status: result[:http_status] || :bad_request,
      json: result.slice(:all_dashboards, :message, :status)
    }
  end
end
