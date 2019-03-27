# frozen_string_literal: true

# Finder for retrieving project registries that are retrying verification
# scoped to a type (repository or wiki) using cross-database joins
# for selective sync.
#
# Basic usage:
#
#     Geo::LegacyProjectRegistryRetryingVerificationFinder.new(current_node: Gitlab::Geo.current_node, :repository).execute
#
# Valid `type` values are:
#
# * `:repository`
# * `:wiki`
#
# Any other value will be ignored.
module Geo
  class LegacyProjectRegistryRetryingVerificationFinder < RegistryFinder
    def initialize(current_node: nil, type:)
      super(current_node: current_node)
      @type = type.to_s.to_sym
    end

    def execute
      if selective_sync?
        registries_retrying_verification_for_selective_sync
      else
        registries_retrying_verification
      end
    end

    private

    attr_reader :type

    def registries_retrying_verification
      Geo::ProjectRegistry.retrying_verification(type)
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def registries_retrying_verification_for_selective_sync
      legacy_inner_join_registry_ids(
        registries_retrying_verification,
        current_node.projects.pluck(:id),
        Geo::ProjectRegistry,
        foreign_key: :project_id
      )
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
