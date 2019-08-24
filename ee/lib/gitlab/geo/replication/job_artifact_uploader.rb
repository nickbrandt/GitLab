# frozen_string_literal: true

module Gitlab
  module Geo
    module Replication
      # This class is responsible for:
      #   * Finding an ::Ci::JobArtifact record
      #   * Returning the necessary response data to send the file back
      #
      class JobArtifactUploader < BaseUploader
        def execute
          job_artifact = fetch_resource

          unless job_artifact.present?
            return error('Job artifact not found')
          end

          unless job_artifact.file.present? && job_artifact.file.exists?
            log_error("Could not upload job artifact because it does not have a file", id: job_artifact.id)

            return file_not_found(job_artifact)
          end

          success(job_artifact.file)
        end

        private

        # rubocop: disable CodeReuse/ActiveRecord

        def fetch_resource
          ::Ci::JobArtifact.find_by(id: object_db_id)
        end

        # rubocop: enable CodeReuse/ActiveRecord
      end
    end
  end
end
