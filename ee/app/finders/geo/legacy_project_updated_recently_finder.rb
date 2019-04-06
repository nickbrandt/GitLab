# frozen_string_literal: true

# Finder for retrieving projects updated recently that
# belong to a specific shard using cross-database joins.
#
# Basic usage:
#
#     Geo::LegacyProjectUpdatedRecentlyFinder
#       .new(current_node: Gitlab::Geo.current_node, shard_name: 'default', batch_size: 1000)
#       .execute
module Geo
  class LegacyProjectUpdatedRecentlyFinder < RegistryFinder
    def initialize(current_node: nil, shard_name:, batch_size:)
      super(current_node: current_node)
      @shard_name = shard_name
      @batch_size = batch_size
    end

    # rubocop:disable CodeReuse/ActiveRecord
    def execute
      registries = find_registries_to_resync
      return Project.none if registries.empty?

      id_and_last_sync_values = registries.map do |id, last_repository_synced_at|
        "(#{id}, #{quote_value(last_repository_synced_at)})"
      end

      projects = current_node.projects.within_shards(shard_name)

      joined_relation = projects.joins(<<~SQL)
        INNER JOIN
        (VALUES #{id_and_last_sync_values.join(',')})
        project_registry(id, last_repository_synced_at)
        ON #{Project.table_name}.id = project_registry.id
      SQL

      joined_relation
        .limit(batch_size)
    end
    # rubocop:enable CodeReuse/ActiveRecord

    private

    attr_reader :batch_size, :shard_name

    # rubocop:disable CodeReuse/ActiveRecord
    def find_registries_to_resync
      Geo::ProjectRegistry
        .dirty
        .retry_due
        .pluck(:project_id, :last_repository_synced_at)
    end
    # rubocop:enable CodeReuse/ActiveRecord
  end
end
