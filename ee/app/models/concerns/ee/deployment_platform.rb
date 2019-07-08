# frozen_string_literal: true

module EE
  module DeploymentPlatform
    extend ::Gitlab::Utils::Override

    override :find_platform_kubernetes_with_cte
    def find_platform_kubernetes_with_cte(environment)
      return super unless environment && feature_available?(:multiple_clusters)

      ::Clusters::ClustersHierarchy.new(self).base_and_ancestors
        .enabled
        .on_environment(environment, relevant_only: true)
        .first&.platform_kubernetes
    end

    override :find_cluster_platform_kubernetes
    def find_cluster_platform_kubernetes(environment: nil)
      return super unless environment && feature_available?(:multiple_clusters)

      clusters.enabled
        .on_environment(environment)
        .last&.platform_kubernetes
    end

    override :find_group_cluster_platform_kubernetes
    def find_group_cluster_platform_kubernetes(environment: nil)
      return super unless environment && feature_available?(:multiple_clusters)

      # With relevant_only: true
      # on_environment use CASE which returns numbers in ascending order
      # So we can use `hierarchy_order: :asc` + first
      ::Clusters::Cluster
        .enabled
        .on_environment(environment, relevant_only: true)
        .ancestor_clusters_for_clusterable(self, hierarchy_order: :asc)
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
