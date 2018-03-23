module Gitlab
  module Geo
    module ProjectLogHelpers
      include LogHelpers

      def base_log_data(message)
        {
          class: self.class.name,
          project_id: project.id,
          project_path: project.full_path,
<<<<<<< HEAD
          message: message
        }
=======
          storage_version: project.storage_version,
          message: message,
          job_id: get_sidekiq_job_id
        }.compact
>>>>>>> 89d997230bb... Merge branch '4994-geo-log-jid-for-sync-related-jobs' into 'master'
      end
    end
  end
end
