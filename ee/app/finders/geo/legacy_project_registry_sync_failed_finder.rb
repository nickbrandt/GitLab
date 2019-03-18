# frozen_string_literal: true

# Finder for retrieving project registries that synchronization have
# failed scoped to a type (repository or wiki) using cross-database
# joins for selective sync.
#
# Basic usage:
#
#     Geo::LegacyProjectRegistrySyncFailedFinder.new(current_node: Gitlab::Geo.current_node, :repository).execute
#
# Valid `type` values are:
#
# * `:repository`
# * `:wiki`
#
# Any other value will be ignored.
module Geo
  class LegacyProjectRegistrySyncFailedFinder < RegistryFinder
    def initialize(current_node: nil, type:)
      super(current_node: current_node)
      @type = type.to_s.to_sym
    end

    def execute
      if selective_sync?
        failed_registries_for_selective_sync
      else
        failed_registries
      end
    end

    private

    attr_reader :type

    def failed_registries
      Geo::ProjectRegistry.sync_failed(type)
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def failed_registries_for_selective_sync
      legacy_inner_join_registry_ids(
        failed_registries,
        current_node.projects.pluck(:id),
        Geo::ProjectRegistry,
        foreign_key: :project_id
      )
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
