# frozen_string_literal: true

# Finder for retrieving projects updated recently that belong to a specific
# shard using FDW queries.
#
# Basic usage:
#
#     Geo::ProjectUpdatedRecentlyFinder
#       .new(current_node: Gitlab::Geo.current_node, shard_name: 'default', batch_size: 1000)
#       .execute.
module Geo
  class ProjectUpdatedRecentlyFinder
    def initialize(current_node:, shard_name:, batch_size:)
      @current_node = Geo::Fdw::GeoNode.find(current_node.id)
      @shard_name = shard_name
      @batch_size = batch_size
    end

    # rubocop:disable CodeReuse/ActiveRecord
    def execute
      return Geo::Fdw::Project.none unless valid_shard?

      projects
        .recently_updated
        .within_shards(shard_name)
        .limit(batch_size)
    end
    # rubocop:enable CodeReuse/ActiveRecord

    private

    attr_reader :current_node, :shard_name, :batch_size

    def projects
      return Geo::Fdw::Project.all if current_node.selective_sync_by_shards?

      current_node.projects
    end

    def valid_shard?
      return true unless current_node.selective_sync_by_shards?

      current_node.selective_sync_shards.include?(shard_name)
    end
  end
end
