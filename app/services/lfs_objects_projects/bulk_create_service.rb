# frozen_string_literal: true

module LfsObjectsProjects
  class BulkCreateService < BaseService
    def initialize(project, params = {})
      @project = project
      @params = params
    end

    def execute
      target_project = params[:target_project]

      return unless target_project.present?

      Gitlab::Database.bulk_insert(
        LfsObjectsProject.table_name,
        lfs_objects_projects_map(target_project),
        on_conflict: :do_nothing
      )
    end

    private

    # rubocop: disable CodeReuse/ActiveRecord
    def lfs_objects_projects_map(target_project)
      project.lfs_objects_projects.where.not(lfs_object: target_project.lfs_objects).map do |objects_project|
        {
          lfs_object_id: objects_project.lfs_object_id,
          project_id: target_project.id,
          repository_type: objects_project.read_attribute_before_type_cast(:repository_type)
        }
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
