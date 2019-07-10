# frozen_string_literal: true

module EE
  module Gitlab
    module BackgroundMigration
      module RollbackImportStateData
        extend ::Gitlab::Utils::Override

        override :move_attributes_data_to_project
        def move_attributes_data_to_project(start_id, end_id)
          Rails.logger.info("#{self.class.name} - Moving import attributes data to projects table: #{start_id} - #{end_id}") # rubocop:disable Gitlab/RailsLogger

          if ::Gitlab::Database.mysql?
            ActiveRecord::Base.connection.execute <<~SQL
              UPDATE projects, project_mirror_data
              SET
                projects.import_status = project_mirror_data.status,
                projects.import_jid = project_mirror_data.jid,
                projects.mirror_last_update_at = project_mirror_data.last_update_at,
                projects.mirror_last_successful_update_at = project_mirror_data.last_successful_update_at,
                projects.import_error = project_mirror_data.last_error
              WHERE project_mirror_data.project_id = projects.id
              AND project_mirror_data.id BETWEEN #{start_id} AND #{end_id}
            SQL
          else
            ActiveRecord::Base.connection.execute <<~SQL
              UPDATE projects
              SET
                import_status = project_mirror_data.status,
                import_jid = project_mirror_data.jid,
                mirror_last_update_at = project_mirror_data.last_update_at,
                mirror_last_successful_update_at = project_mirror_data.last_successful_update_at,
                import_error = project_mirror_data.last_error
              FROM project_mirror_data
              WHERE project_mirror_data.project_id = projects.id
              AND project_mirror_data.id BETWEEN #{start_id} AND #{end_id}
            SQL
          end
        end
      end
    end
  end
end
