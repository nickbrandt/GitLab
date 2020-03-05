# frozen_string_literal: true

module Geo
  module BlobReplicatorStrategy
    extend ActiveSupport::Concern

    included do
      event :created
    end

    class_methods do
    end

    def handle_after_create_commit
      publish(:created, **created_params)
    end

    # Called by Gitlab::Geo::Replicator#consume
    def consume_created_event
      download
    end

    def carrierwave_uploader
      raise NotImplementedError
    end

    private

    def download
      ::Geo::BlobDownloadService.new(replicator: self).execute
    end

    def created_params
      { model_record_id: model_record.id }
    end
  end
end
