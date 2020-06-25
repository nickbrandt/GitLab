# frozen_string_literal: true
module Projects
  class MetricsDashboardController < Projects::ApplicationController
    before_action :authorize_metrics_dashboard!
    before_action do
      push_frontend_feature_flag(:prometheus_computed_alerts)
    end

    def show
      if environment
        render 'projects/environments/metrics'
      else
        render_404
      end
    end

    private

    def environment
      @environment ||=
        if params[:environment]
          project.environments.find(params[:environment])
        else
          project.default_environment
        end
    end
  end
end
