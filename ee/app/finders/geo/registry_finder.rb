# frozen_string_literal: true

module Geo
  class RegistryFinder
    include ::Gitlab::Utils::StrongMemoize

    attr_reader :current_node_id

    def initialize(current_node_id: nil)
      @current_node_id = current_node_id
    end

    # @!method find_registry_differences
    #    Returns untracked IDs as well as tracked IDs that are unused.
    #
    #    Untracked IDs are model IDs that are supposed to be synced but don't yet
    #    have a registry entry.
    #
    #    Unused tracked IDs are model IDs that are not supposed to be synced but
    #    already have a registry entry. For example:
    #
    #      - orphaned registries
    #      - records that became excluded from selective sync
    #      - records that are in object storage, and `sync_object_storage` became
    #        disabled
    #
    #    We compute both sets in this method to reduce the number of DB queries
    #    performed.
    #
    # @return [Array] the first element is an Array of untracked IDs, and the second element is an Array of tracked IDs that are unused
    def find_registry_differences(range)
      source_ids = replicables.id_in(range).pluck(replicable_primary_key) # rubocop:disable CodeReuse/ActiveRecord
      tracked_ids = registry_class.pluck_model_ids_in_range(range)

      untracked_ids = source_ids - tracked_ids
      unused_tracked_ids = tracked_ids - source_ids

      [untracked_ids, unused_tracked_ids]
    end

    # @!method registry_class
    #    Return an ActiveRecord::Base class for the tracked type
    def registry_class
      raise NotImplementedError,
        "#{self.class} does not implement #{__method__}"
    end

    # @!method replicables
    #    Return an ActiveRecord::Relation of the replicable records for the
    #    tracked file_type(s)
    def replicables
      raise NotImplementedError,
        "#{self.class} does not implement #{__method__}"
    end

    # @!method registry_count
    #    Return a count of the registry records for the tracked type(s)
    def registry_count
      registry_class.count
    end

    # @!method synced_count
    #    Return a count of the registry records for the tracked type
    #    that are synced
    def synced_count
      registry_class.synced.count
    end

    # @!method failed_count
    #    Return a count of the registry records for the tracked type
    #    that are sync failed
    def failed_count
      registry_class.failed.count
    end

    private

    def current_node
      strong_memoize(:current_node) do
        GeoNode.find(current_node_id) if current_node_id
      end
    end

    # @!method registry_class
    #    Return the fully qualified name of the replicable primary key for the
    #    tracked file_type(s)
    def replicable_primary_key
      registry_class::MODEL_CLASS.arel_table[:id]
    end
  end
end
