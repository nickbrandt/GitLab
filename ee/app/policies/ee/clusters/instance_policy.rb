# frozen_string_literal: true

module EE
  module Clusters
    module InstancePolicy
      extend ActiveSupport::Concern

      prepended do
        with_scope :global
        condition(:cluster_deployments_available) do
          License.feature_available?(:cluster_deployments)
        end

        with_scope :global
        condition(:cluster_health_available) do
          License.feature_available?(:cluster_health)
        end

        rule { can?(:read_cluster) & cluster_deployments_available }
          .enable :read_cluster_environments

        rule { can?(:read_cluster) & cluster_health_available }.enable :read_cluster_health
      end
    end
  end
end
