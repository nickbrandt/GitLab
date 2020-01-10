# frozen_string_literal: true

module Geo
  # Finder for retrieving designs updated recently that belong to a specific
  # shard using FDW queries.
  #
  # Basic usage:
  #
  #     Geo::DesignUpdatedRecentlyFinder
  #       .new(shard_name: 'default', batch_size: 1000)
  #       .execute.
  class DesignUpdatedRecentlyFinder
    def initialize(scheduled_project_ids: [], shard_name:, batch_size: nil)
      @current_node = Geo::Fdw::GeoNode.find(Gitlab::Geo.current_node.id)
      @scheduled_project_ids = scheduled_project_ids
      @shard_name = shard_name
      @batch_size = batch_size
    end

    # rubocop:disable CodeReuse/ActiveRecord
    def execute
      return Geo::Fdw::Project.none unless valid_shard?

      relation = projects
        .with_designs
        .recently_updated_designs
        .within_shards(shard_name)
        .id_not_in(scheduled_project_ids)
        .order('design_registry.last_synced_at ASC NULLS FIRST')
      relation = relation.limit(batch_size) unless batch_size.nil?
      relation.pluck_primary_key
    end
    # rubocop:enable CodeReuse/ActiveRecord

    private

    attr_reader :scheduled_project_ids, :current_node, :shard_name, :batch_size

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
