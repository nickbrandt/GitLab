# frozen_string_literal: true

module Geo
  # Accepts a registry class, queries the next batch of replicable records, and
  # creates any missing registries.
  class RegistryConsistencyService
    include ::Gitlab::Geo::LogHelpers

    attr_reader :registry_class, :model_class, :batch_size

    def initialize(registry_class, batch_size:)
      @registry_class = registry_class
      @model_class = registry_class::MODEL_CLASS
      @batch_size = batch_size
    end

    def execute
      range = next_range!
      return unless range

      created_in_range = create_missing_in_range(range)
      created_above = create_missing_above(end_of_batch: range.last)

      created_in_range.any? ||
        created_above.any?
    rescue => e
      log_error("Error while backfilling #{registry_class}", e)

      raise
    end

    private

    # @return [Range] the next range of a batch of records
    def next_range!
      Gitlab::LoopingBatcher.new(model_class, key: batcher_key, batch_size: batch_size).next_range!
    end

    def batcher_key
      "registry_consistency:#{registry_class.name.parameterize}"
    end

    # @return [Array] the list of IDs of created records
    def create_missing_in_range(range)
      untracked, _ = find_registry_differences(range)
      return [] if untracked.empty?

      created = registry_class.insert_for_model_ids(untracked)

      log_created(range, untracked, created)

      created
    end

    def find_registry_differences(range)
      finder.find_registry_differences(range)
    end

    def finder
      @finder ||= registry_class.finder_class.new(current_node_id: Gitlab::Geo.current_node.id)
    end

    # This hack is used to sync new files soon after they are created.
    #
    # This is not needed for replicables that have already implemented
    # create events.
    #
    # @param [Integer] the last ID of the batch processed in create_missing_in_range
    # @return [Array] the list of IDs of created records
    def create_missing_above(end_of_batch:)
      return [] if registry_class.has_create_events?

      last_id = model_class.last.id

      # When the LoopingBatcher will soon approach the end of the table, it
      # finds the records at the end of the table anyway, so conserve resources.
      return [] if batch_close_to_the_end?(end_of_batch, last_id)

      # Try to call this service often enough that batch_size is greater than
      # the number of recently created records since last call.
      start = last_id - batch_size + 1
      finish = last_id

      create_missing_in_range(start..finish)
    end

    # Returns true when LoopingBatcher will soon return ranges near the end of
    # the table.
    #
    # @return [Boolean] true if the end_of_batch ID is near the end of the table
    def batch_close_to_the_end?(end_of_batch, last_id)
      last_id < end_of_batch + 5 * batch_size
    end

    def log_created(range, untracked, created)
      log_info(
        "Created registry entries",
        {
          registry_class: registry_class.name,
          start: range.first,
          finish: range.last,
          created: created.size,
          failed_to_create: untracked.size - created.size
        }
      )
    end
  end
end
