# frozen_string_literal: true

module Gitlab
  module Geo
    # This class is responsible for:
    #   * Requesting an ::Ci::JobArtifact file from the primary
    #   * Saving it in the right place on successful download
    #   * Returning a detailed Result object
    class JobArtifactTransfer < Transfer
      def initialize(job_artifact)
        super(
          :job_artifact,
          job_artifact.id,
          job_artifact.file.path,
          job_artifact.file_sha256,
          job_artifact_request_data(job_artifact)
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
