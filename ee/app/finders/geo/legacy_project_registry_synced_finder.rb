# frozen_string_literal: true

# Finder for retrieving project registries that have been synced
# scoped to a type (repository or wiki) using cross-database joins.
#
# Basic usage:
#
#     Geo::LegacyProjectRegistrySyncedFinder.new(current_node: Gitlab::Geo.current_node, :repository).execute
#
# Valid `type` values are:
#
# * `:repository`
# * `:wiki`
#
# Any other value will be ignored.
module Geo
  class LegacyProjectRegistrySyncedFinder < RegistryFinder
    def initialize(current_node:, type:)
      super(current_node: current_node)
      @type = type.to_sym
    end

    def execute
      legacy_inner_join_registry_ids(
        Geo::ProjectRegistry.synced(type),
        current_node.projects.pluck_primary_key,
        Geo::ProjectRegistry,
        foreign_key: :project_id
      )
    end

    private

    attr_reader :type
  end
end
