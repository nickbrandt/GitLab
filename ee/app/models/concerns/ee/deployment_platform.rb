# frozen_string_literal: true

module EE
  module DeploymentPlatform
    extend ::Gitlab::Utils::Override

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

      # on_environment use CASE which returns numbers in descending order
      # So we have to use `hierarchy_order: :desc` + last
      ::Clusters::Cluster
        .enabled
        .on_environment(environment)
        .ancestor_clusters_for_clusterable(self, hierarchy_order: :desc)
        .last&.platform_kubernetes
    end
  end
end
