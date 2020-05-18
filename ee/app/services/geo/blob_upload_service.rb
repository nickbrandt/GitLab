# frozen_string_literal: true

module Geo
  class BlobUploadService
    attr_reader :replicable_name, :blob_id, :checksum, :replicator

    def initialize(replicable_name:, blob_id:, decoded_params:)
      @replicable_name = replicable_name
      @blob_id = blob_id
      @checksum = decoded_params.delete(:checksum)

      replicator_klass = Gitlab::Geo::Replicator.for_replicable_name(replicable_name)
      @replicator = replicator_klass.new(model_record_id: blob_id)
    end

    def execute
      retriever.execute
    end

    def retriever
      Gitlab::Geo::Replication::BlobRetriever.new(replicator: replicator, checksum: checksum)
    end
  end
end
