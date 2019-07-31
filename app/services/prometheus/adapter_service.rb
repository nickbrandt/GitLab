# frozen_string_literal: true

module Prometheus
  class AdapterService
    def initialize(project, deployment_platform: nil, cluster: nil)
      @project = project

      @cluster = cluster || deployment_platform&.cluster
    end

    attr_reader :project

    def prometheus_adapter
      @prometheus_adapter ||= if service_prometheus_adapter.can_query?
                                service_prometheus_adapter
                              else
                                cluster_prometheus_adapter
                              end
    end

    def service_prometheus_adapter
      project.find_or_initialize_service('prometheus')
    end

    def cluster_prometheus_adapter
      cluster = @cluster || cluster_with_prometheus

      application = cluster&.application_prometheus

      application if application&.available?
    end

    private

    def cluster_with_prometheus
      ::Clusters::ClustersHierarchy.new(project)
        .base_and_ancestors
        .enabled
        .select(&:application_prometheus_available?)
        .first
    end
  end
end
