# frozen_string_literal: true

class DeploymentMetrics
  include Gitlab::Utils::StrongMemoize

  attr_reader :project, :deployment

  delegate :cluster, to: :deployment

  def initialize(project, deployment)
    @project = project
    @deployment = deployment
  end

  def has_metrics?
    deployment.success? && prometheus_adapter&.configured?
  end

  def metrics
    return {} unless has_metrics_and_can_query?

    metrics = prometheus_adapter.query(:deployment, deployment)
    metrics&.merge(deployment_time: deployment.finished_at.to_i) || {}
  end

  def additional_metrics
    return {} unless has_metrics_and_can_query?

    metrics = prometheus_adapter.query(:additional_metrics_deployment, deployment)
    metrics&.merge(deployment_time: deployment.finished_at.to_i) || {}
  end

  private

  def has_metrics_and_can_query?
    has_metrics? && prometheus_adapter.can_query?
  end

  # rubocop: disable CodeReuse/ServiceClass
  def prometheus_adapter
    @prometheus_adapter ||= Prometheus::AdapterService.new(project, cluster).prometheus_adapter
  end
  # rubocop: enable CodeReuse/ServiceClass

  def has_metrics_and_can_query?
    has_metrics? && prometheus_adapter.can_query?
  end
end
