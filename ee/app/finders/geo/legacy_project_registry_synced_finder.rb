# frozen_string_literal: true

# Finder for retrieving project registries that have been synced
# scoped to a type (repository or wiki) using cross-database joins
# for selective sync.
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
      if selective_sync?
        synced_registries_for_selective_sync
      else
        synced_registries
      end
    end

    private

    attr_reader :type

    def synced_registries
      Geo::ProjectRegistry.synced(type)
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def synced_registries_for_selective_sync
      legacy_inner_join_registry_ids(
        synced_registries,
        current_node.projects.pluck(:id),
        Geo::ProjectRegistry,
        foreign_key: :project_id
      )
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
