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

    # @!method find_never_synced_registries
    #    Return an ActiveRecord::Relation of the registry records for the
    #    tracked ype that have never been synced.
    #
    #    Does not care about selective sync, because it considers the Registry
    #    table to be the single source of truth. The contract is that other
    #    processes need to ensure that the table only contains records that should
    #    be synced.
    #
    #    Any registries that have ever been synced that currently need to be
    #    resynced will be handled by other find methods (like
    #    #find_retryable_failed_registries)
    #
    #    You can pass a list with `except_ids:` so you can exclude items you
    #    already scheduled but haven't finished and aren't persisted to the database yet
    #
    # @param [Integer] batch_size used to limit the results returned
    # @param [Array<Integer>] except_ids ids that will be ignored from the query
    #
    # rubocop:disable CodeReuse/ActiveRecord
    def find_never_synced_registries(batch_size:, except_ids: [])
      registry_class
        .never_synced
        .model_id_not_in(except_ids)
        .limit(batch_size)
    end
    # rubocop:enable CodeReuse/ActiveRecord

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
