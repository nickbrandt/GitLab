# frozen_string_literal: true

module Projects
  class UpdateRepositoryStorageService < BaseService
    include Gitlab::ShellAdapter

    RepositoryAlreadyMoved = Class.new(StandardError)

    def initialize(project)
      @project = project
    end

    def execute(new_repository_storage_key)
      # Raising an exception is a little heavy handed but this behavior (doing
      # nothing if the repo is already on the right storage) prevents data
      # loss, so it is valuable for us to be able to observe it via the
      # exception.
      raise RepositoryAlreadyMoved if project.repository_storage == new_repository_storage_key

      result = mirror_repository(new_repository_storage_key)

      if project.wiki.repository_exists?
        result &&= mirror_repository(new_repository_storage_key, type: Gitlab::GlRepository::WIKI)
      end

      if project.design_repository.exists?
        result &&= mirror_repository(new_repository_storage_key, type: Gitlab::GlRepository::DESIGN)
      end

      if result
        mark_old_paths_for_archive

        project.update(repository_storage: new_repository_storage_key, repository_read_only: false)
        project.leave_pool_repository
        project.track_project_repository
      else
        project.update(repository_read_only: false)
      end
    end

    private

    def mirror_repository(new_storage_key, type: Gitlab::GlRepository::PROJECT)
      return false unless wait_for_pushes(type)

      repository = type.repository_for(project)
      full_path = repository.full_path
      raw_repository = repository.raw

      # Initialize a git repository on the target path
      gitlab_shell.create_repository(new_storage_key, raw_repository.relative_path, full_path)
      new_repository = Gitlab::Git::Repository.new(new_storage_key,
                                                   raw_repository.relative_path,
                                                   raw_repository.gl_repository,
                                                   full_path)

      new_repository.fetch_repository_as_mirror(raw_repository)
    end

    def mark_old_paths_for_archive
      old_repository_storage = project.repository_storage
      new_project_path = moved_path(project.disk_path)

      # Notice that the block passed to `run_after_commit` will run with `project`
      # as its context
      project.run_after_commit do
        GitlabShellWorker.perform_async(:mv_repository,
                                        old_repository_storage,
                                        disk_path,
                                        new_project_path)

        if wiki.repository_exists?
          GitlabShellWorker.perform_async(:mv_repository,
                                          old_repository_storage,
                                          wiki.disk_path,
                                          "#{new_project_path}.wiki")
        end

        if design_repository.exists?
          GitlabShellWorker.perform_async(:mv_repository,
                                          old_repository_storage,
                                          design_repository.disk_path,
                                          "#{new_project_path}.design")
        end
      end
    end

    def moved_path(path)
      "#{path}+#{project.id}+moved+#{Time.now.to_i}"
    end

    def wait_for_pushes(type)
      reference_counter = project.reference_counter(type: type)

      # Try for 30 seconds, polling every 10
      3.times do
        return true if reference_counter.value == 0

        sleep 10
      end

      false
    end
  end
end
