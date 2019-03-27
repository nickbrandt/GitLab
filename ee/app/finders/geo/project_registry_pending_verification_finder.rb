# frozen_string_literal: true

# Finder for retrieving project registries that that need a repository or
# wiki verification where projects belong to the specific shard using
# FDW queries.
#
# Basic usage:
#
#     Geo::ProjectRegistryPendingVerificationFinder
#       .new(current_node: Gitlab::Geo.current_node, shard_name: 'default', batch_size: 1000)
#       .execute.
module Geo
  class ProjectRegistryPendingVerificationFinder
    def initialize(current_node:, shard_name:, batch_size:)
      @current_node = Geo::Fdw::GeoNode.find(current_node.id)
      @shard_name = shard_name
      @batch_size = batch_size
    end

    def execute
      current_node.project_registries
        .joins(Geo::Fdw::GeoNode.fdw_inner_join_projects)
        .joins(Geo::Fdw::GeoNode.fdw_inner_join_repository_state)
        .where(Geo::Fdw::GeoNode.fdw_registries_pending_verification)
        .where(Geo::Fdw::Project.within_shard(shard_name))
        .limit(batch_size)
    end

    private

    attr_reader :current_node, :shard_name,:batch_size
  end
end
