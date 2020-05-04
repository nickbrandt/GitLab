# frozen_string_literal: true

module EE
  module Projects
    module UpdateRepositoryStorageService
      extend ::Gitlab::Utils::Override

      override :mirror_repositories
      def mirror_repositories(new_repository_storage_key)
        super

        if project.design_repository.exists?
          mirror_repository(new_repository_storage_key, type: ::Gitlab::GlRepository::DESIGN)
        end
      end

      override :mark_old_paths_for_archive
      def mark_old_paths_for_archive
        super

        old_repository_storage = project.repository_storage
        new_project_path = moved_path(project.disk_path)

        project.run_after_commit do
          if design_repository.exists?
            GitlabShellWorker.perform_async(:mv_repository,
                                            old_repository_storage,
                                            design_repository.disk_path,
                                            "#{new_project_path}.design")
          end
        end
      end
    end
  end
end
