# frozen_string_literal: true

# Finder for retrieving project registries that need a repository or
# wiki verification where projects belong to the specific shard
# using cross-database joins for selective sync.
#
# Basic usage:
#
#     Geo::LegacyProjectRegistryPendingVerificationFinder
#       .new(current_node: Gitlab::Geo.current_node, shard_name: 'default', batch_size: 1000)
#       .execute
module Geo
  class LegacyProjectRegistryPendingVerificationFinder < RegistryFinder
    def initialize(current_node: nil, shard_name:, batch_size:)
      super(current_node: current_node)
      @shard_name = shard_name
      @batch_size = batch_size
    end

    def execute
      if use_legacy_queries?
        registries_pending_verification_for_selective_sync
      else
        registries_pending_verification
      end
    end

    private

    attr_reader :batch_size, :shard_name

    # rubocop:disable CodeReuse/ActiveRecord
    def registries_pending_verification
      Geo::ProjectRegistry.all
        .merge(Geo::Fdw::ProjectRegistry.registries_pending_verification)
        .merge(Geo::Fdw::ProjectRegistry.within_shards(shard_name))
        .limit(batch_size)
    end
    # rubocop:enable CodeReuse/ActiveRecord

    # rubocop:disable CodeReuse/ActiveRecord
    def registries_pending_verification_for_selective_sync
      registries = Geo::ProjectRegistry
        .where(Geo::ProjectRegistry.registries_pending_verification)
        .pluck(:project_id, Geo::ProjectRegistry.repositories_pending_verification.to_sql, Geo::ProjectRegistry.wikis_pending_verification.to_sql)

      return Geo::ProjectRegistry.none if registries.empty?

      id_and_want_to_sync = registries.map do |project_id, want_to_sync_repo, want_to_sync_wiki|
        "(#{project_id}, #{quote_value(want_to_sync_repo)}, #{quote_value(want_to_sync_wiki)})"
      end

      legacy_repository_state_table = ::ProjectRepositoryState.arel_table
      project_registry_sync_table = Arel::Table.new(:project_registry_sync_table)

      joined_relation =
        ProjectRepositoryState.joins(<<~SQL_REPO)
          INNER JOIN
          (VALUES #{id_and_want_to_sync.join(',')})
          project_registry_sync_table(project_id, want_to_sync_repo, want_to_sync_wiki)
          ON #{legacy_repository_state_table.name}.project_id = project_registry_sync_table.project_id
        SQL_REPO

      project_ids = joined_relation
        .joins(:project)
        .where(projects: { repository_storage: shard_name })
        .where(
          legacy_repository_state_table[:repository_verification_checksum].not_eq(nil)
            .and(project_registry_sync_table[:want_to_sync_repo].eq(true))
          .or(legacy_repository_state_table[:wiki_verification_checksum].not_eq(nil)
            .and(project_registry_sync_table[:want_to_sync_wiki].eq(true))))
        .limit(batch_size)
        .pluck(:project_id)

      legacy_inner_join_registry_ids(
        Geo::ProjectRegistry.where(project_id: project_ids),
        current_node.projects.pluck(:id),
        Geo::ProjectRegistry,
        foreign_key: :project_id
      )
    end
    # rubocop:enable CodeReuse/ActiveRecord
  end
end
