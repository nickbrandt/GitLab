# frozen_string_literal: true

# Finder for retrieving unsynced projects that belong to a specific
# shard using cross-database joins.
#
# Basic usage:
#
#     Geo::LegacyProjectUnsyncedFinder
#       .new(current_node: Gitlab::Geo.current_node, shard_name: 'default', batch_size: 1000)
#       .execute
module Geo
  class LegacyProjectUnsyncedFinder < RegistryFinder
    def initialize(current_node: nil, shard_name:, batch_size:)
      super(current_node: current_node)
      @shard_name = shard_name
      @batch_size = batch_size
    end

    # rubocop:disable CodeReuse/ActiveRecord
    def execute
      legacy_left_outer_join_registry_ids(
        current_node.projects.within_shards(shard_name),
        Geo::ProjectRegistry.pluck_project_key,
        Project
      ).limit(batch_size)
    end
    # rubocop:enable CodeReuse/ActiveRecord

    private

    attr_reader :batch_size, :shard_name
  end
end
