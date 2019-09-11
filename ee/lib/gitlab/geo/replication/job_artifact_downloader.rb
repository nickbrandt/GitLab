# frozen_string_literal: true

module Gitlab
  module Geo
    module Replication
      # This class is responsible for:
      #   * Finding a ::Ci::JobArtifact record
      #   * Requesting and downloading the JobArtifact's file from the primary
      #   * Returning a detailed Result
      #
      class JobArtifactDownloader < BaseDownloader
        def execute
          job_artifact = find_resource
          return fail_before_transfer unless job_artifact.present?

          transfer = ::Gitlab::Geo::Replication::JobArtifactTransfer.new(job_artifact)
          Result.from_transfer_result(transfer.download_from_primary)
        end

        private

        def find_resource
          ::Ci::JobArtifact.find_by_id(object_db_id)
        end
      end
    end
  end
end
