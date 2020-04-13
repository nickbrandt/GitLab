# frozen_string_literal: true

module Geo
  class BlobUploadService
    include ExclusiveLeaseGuard
    include ::Gitlab::Geo::LogHelpers

    attr_reader :replicable_name, :blob_id, :checksum, :replicator

    def initialize(replicable_name:, blob_id:, decoded_params:)
      @replicable_name = replicable_name
      @blob_id = blob_id
      @checksum = decoded_params.delete(:checksum)

      replicator_klass = Gitlab::Geo::Replicator.for_replicable_name(replicable_name)
      @replicator = replicator_klass.new(model_record_id: blob_id)

      fail_unimplemented!(replicable_name) unless @replicator
    end

    def execute
      retriever.execute
    end

    def retriever
      Gitlab::Geo::Replication::BlobRetriever.new(replicator: replicator, checksum: checksum)
    end

    private

    def fail_unimplemented!(replicable_name)
      error_message = "Cannot find a Geo::Replicator for #{replicable_name}"

      log_error(error_message)

      raise NotImplementedError, error_message
    end

    # This is called by LogHelpers to build json log with context info
    #
    # @see ::Gitlab::Geo::LogHelpers
    def extra_log_data
      {
        replicable_name: replicable_name,
        blob_id: blob_id
      }.compact
    end
  end
end
