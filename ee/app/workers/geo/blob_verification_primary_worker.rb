# frozen_string_literal: true

module Geo
  class BlobVerificationPrimaryWorker
    include ApplicationWorker
    include GeoQueue
    include ::Gitlab::Geo::LogHelpers

    sidekiq_options retry: 3, dead: false

    idempotent!

    def perform(replicable_name, replicable_id)
      replicator_class = ::Gitlab::Geo::Replicator.for_replicable_name(replicable_name)
      replicator = replicator_class.new(model_record_id: replicable_id)

      replicator.calculate_checksum!
    rescue ActiveRecord::RecordNotFound
      log_error("Couldn't find the blob, skipping", replicable_name: replicable_name, replicable_id: replicable_id)
    end
  end
end
