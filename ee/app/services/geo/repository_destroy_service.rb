# frozen_string_literal: true

module Geo
  class RepositoryDestroyService
    include ::Gitlab::Geo::LogHelpers

    attr_reader :id, :name, :disk_path, :repository_storage

    def initialize(id, name, disk_path, repository_storage)
      @id = id
      @name = name
      @disk_path = disk_path
      @repository_storage = repository_storage
    end

    def async_execute
      GeoRepositoryDestroyWorker.perform_async(id, name, disk_path, repository_storage)
    end

    def execute
      destroy_project
      destroy_registry_entries
    rescue => e
      log_error('Could not destroy repository', e, project_id: id, shard: repository_storage, disk_path: disk_path)
      destroy_registry_entries
      raise
    end

    private

    def destroy_project
      ::Projects::DestroyService.new(deleted_project, nil).geo_replicate
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def destroy_registry_entries
      ::Geo::ProjectRegistry.where(project_id: id).delete_all
      ::Geo::DesignRegistry.where(project_id: id).delete_all

      log_info("Registry entries removed", project_id: id)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def deleted_project
      # We don't have access to the original model anymore, so we are
      # rebuilding only what our service class requires
      ::Geo::DeletedProject.new(id: id,
                                name: name,
                                disk_path: disk_path,
                                repository_storage: repository_storage)
    end
  end
end
