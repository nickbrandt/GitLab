# frozen_string_literal: true

# Finder for retrieving project registries that need a repository or
# wiki verification where projects belong to the specific shard
# using cross-database joins.
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
      registries = find_registries_pending_verification_on_secondary
      return Geo::ProjectRegistry.none if registries.empty?

      registries_to_verify = filter_registries_verified_in_primary(registries)
      return registries_to_verify unless selective_sync?

      legacy_inner_join_registry_ids(
        registries_to_verify,
        current_node.projects.pluck_primary_key,
        Geo::ProjectRegistry,
        foreign_key: :project_id
      )
    end

    private

    attr_reader :batch_size, :shard_name

    # rubocop:disable CodeReuse/ActiveRecord
    def find_registries_pending_verification_on_secondary
      Geo::ProjectRegistry
        .where(Geo::ProjectRegistry.registries_pending_verification)
        .pluck(
          :project_id,
          Geo::ProjectRegistry.repositories_pending_verification.to_sql,
          Geo::ProjectRegistry.wikis_pending_verification.to_sql
        )
    end
    # rubocop:enable CodeReuse/ActiveRecord

    def filter_registries_verified_in_primary(registries)
      filtered_project_ids = filter_projects_verified_on_primary(registries)
      Geo::ProjectRegistry.project_id_in(filtered_project_ids)
    end

    # rubocop:disable CodeReuse/ActiveRecord
    def filter_projects_verified_on_primary(registries)
      inner_join_project_repository_state(registries)
        .joins(:project)
        .merge(Project.within_shards(shard_name))
        .where(
          legacy_repository_state_table[:repository_verification_checksum].not_eq(nil)
            .and(project_registry_verify_table[:want_to_verify_repo].eq(true))
          .or(legacy_repository_state_table[:wiki_verification_checksum].not_eq(nil)
            .and(project_registry_verify_table[:want_to_verify_wiki].eq(true))))
        .limit(batch_size)
        .pluck_project_key
    end
    # rubocop:enable CodeReuse/ActiveRecord

    # rubocop:disable CodeReuse/ActiveRecord
    def inner_join_project_repository_state(registries)
      id_and_want_to_verify = registries.map do |project_id, want_to_verify_repo, want_to_verify_wiki|
        "(#{project_id}, #{quote_value(want_to_verify_repo)}, #{quote_value(want_to_verify_wiki)})"
      end

      ProjectRepositoryState.joins(<<~SQL_REPO)
        INNER JOIN
        (VALUES #{id_and_want_to_verify.join(',')})
        #{project_registry_verify_table.name}(project_id, want_to_verify_repo, want_to_verify_wiki)
        ON #{legacy_repository_state_table.name}.project_id = #{project_registry_verify_table.name}.project_id
      SQL_REPO
    end
    # rubocop:enable CodeReuse/ActiveRecord

    def legacy_repository_state_table
      @legacy_repository_state_table ||= ProjectRepositoryState.arel_table
    end

    def project_registry_verify_table
      @project_registry_verify_table ||= Arel::Table.new(:project_registry_verify_table)
    end
  end
end
