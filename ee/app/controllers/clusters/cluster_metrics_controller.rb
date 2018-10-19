# frozen_string_literal: true

class Clusters::ClusterMetricsController < Clusters::BaseController
  before_action :cluster, only: :metrics
  before_action :authorize_read_cluster!

  def show
    return render_404 unless prometheus_adapter&.can_query?

    respond_to do |format|
      format.json do
        metrics = prometheus_adapter.query(:cluster) || {}

        if metrics.any?
          render json: metrics
        else
          head :no_content
        end
      end
    end
  end

  private

  def cluster
    @cluster ||= clusterable.clusters.find(params[:id])
      .present(current_user: current_user)
  end

  def prometheus_adapter
    return unless cluster&.application_prometheus_available?

    cluster.application_prometheus
  end
end
