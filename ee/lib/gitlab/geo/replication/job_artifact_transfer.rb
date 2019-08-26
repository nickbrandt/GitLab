# frozen_string_literal: true

module Gitlab
  module Geo
    module Replication
      # This class is responsible for:
      #   * Requesting an ::Ci::JobArtifact file from the primary
      #   * Saving it in the right place on successful download
      #   * Returning a detailed Result object
      class JobArtifactTransfer < BaseTransfer
        def initialize(job_artifact)
          super(
            file_type: :job_artifact,
            file_id: job_artifact.id,
            filename: job_artifact.file.path,
            expected_checksum: job_artifact.file_sha256,
            request_data: job_artifact_request_data(job_artifact)
          )
        end

        private

        def job_artifact_request_data(job_artifact)
          {
            id: job_artifact.id,
            file_type: :job_artifact,
            file_id: job_artifact.id
          }
        end
      end
    end
  end
end
