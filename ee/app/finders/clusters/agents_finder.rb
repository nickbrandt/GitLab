# frozen_string_literal: true

module Clusters
  class AgentsFinder
    def initialize(project, current_user)
      @project = project
      @current_user = current_user
    end

    def execute
      return ::Clusters::Agent.none unless can_read_cluster_agents?

      project.cluster_agents
    end

    private

    attr_reader :project, :current_user

    def can_read_cluster_agents?
      project.feature_available?(:cluster_agents) && current_user.can?(:read_cluster, project)
    end
  end
end
