# frozen_string_literal: true

module Clusters
  class EnvironmentsFinder
    def initialize(cluster, current_user)
      @cluster = cluster
      @current_user = current_user
    end

    def execute
      if can_read_cluster_environments?
        ::Environment.available.deployed_to_cluster(cluster)
      else
        ::Environment.none
      end
    end

    private

    attr_reader :cluster, :current_user

    def can_read_cluster_environments?
      Ability.allowed?(current_user, :read_cluster_environments, cluster)
    end
  end
end
