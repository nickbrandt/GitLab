# frozen_string_literal: true

module EE
  module Gitlab
    module BackgroundMigration
      module CreateSecuritySetting
        extend ::Gitlab::Utils::Override

        class Project < ActiveRecord::Base
          self.table_name = 'projects'

          has_one :security_setting, class_name: 'ProjectSecuritySetting'
        end

        class ProjectSecuritySetting < ActiveRecord::Base
          include BulkInsertSafe

          self.table_name = 'project_security_settings'

          belongs_to :project, inverse_of: :security_setting
        end

        override :perform
        def perform(project_ids)
          projects = Project.left_joins(:security_setting).where(project_security_settings: { project_id: nil })
          projects = Project.find(project_ids)

          projects.each do |project|
            project.security_setting || project.create_security_setting
          end
        end
      end
    end
  end
end
