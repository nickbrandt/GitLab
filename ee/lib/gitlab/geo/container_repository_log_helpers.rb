# frozen_string_literal: true

module Gitlab
  module Geo
    module ContainerRepositoryLogHelpers
      include LogHelpers

      def base_log_data(message)
        {
          class: self.class.name,
          project_id: container_repository.project.id,
          project_path: container_repository.project.full_path,
          container_repository_name: container_repository.name,
          message: message,
          job_id: get_sidekiq_job_id
        }.compact
      end
    end
  end
end
