# frozen_string_literal: true

module Geo
  class DesignRegistryFinder < RegistryFinder
    # rubocop:disable CodeReuse/ActiveRecord
    def find_retryable_dirty_registries(batch_size:, except_ids: [])
      registry_class
        .retryable
        .model_id_not_in(except_ids)
        .order(Gitlab::Database.nulls_first_order(:last_synced_at))
        .limit(batch_size)
    end
    # rubocop:enable CodeReuse/ActiveRecord

    private

    def replicables
      current_node.designs
    end

    def registry_class
      Geo::DesignRegistry
    end
  end
end
