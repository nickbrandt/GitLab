# frozen_string_literal: true

module EE
  module DeploymentPlatform
    extend ::Gitlab::Utils::Override

    override :find_platform_kubernetes_with_cte
    def find_platform_kubernetes_with_cte(environment)
      return super unless environment && feature_available?(:multiple_clusters)

      ::Clusters::ClustersHierarchy.new(self, include_management_project: cluster_management_project_enabled?)
        .base_and_ancestors
        .enabled
        .on_environment(environment, relevant_only: true)
        .first&.platform_kubernetes
    end

    override :find_instance_cluster_platform_kubernetes
    def find_instance_cluster_platform_kubernetes(environment: nil)
      return super unless environment && feature_available?(:multiple_clusters)

      ::Clusters::Instance.new.clusters.enabled.on_environment(environment, relevant_only: true)
        .first&.platform_kubernetes
    end
  end
end
