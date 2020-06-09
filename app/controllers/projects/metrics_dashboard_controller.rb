# frozen_string_literal: true

class Projects::MetricsDashboardController < Projects::ApplicationController
  before_action :metrics_dashboard_page do
    authorize_metrics_dashboard!

    push_frontend_feature_flag(:prometheus_computed_alerts)
  end

  def metrics_dashboard_page
    @environment = if metrics_dashboard_page_params[:environment]
                     project.environments.find(metrics_dashboard_page_params[:environment])
                   else
                     project.default_environment
                   end

    if @environment
      render 'projects/environments/metrics'
    else
      render_404
    end
  end

  private

  def metrics_dashboard_page_params
    params.permit(:environment)
  end
end
