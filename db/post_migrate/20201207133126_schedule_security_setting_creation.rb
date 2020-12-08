# frozen_string_literal: true

class ScheduleSecuritySettingCreation < ActiveRecord::Migration[6.0]
  DOWNTIME = false
  MIGRATION = 'CreateSecuritySetting'.freeze

  disable_ddl_transaction!

  class Project < ActiveRecord::Base
    has_one :security_setting, class_name: 'ProjectSecuritySetting'

    scope :without_security_settings, -> { left_joins(:security_setting).where(project_security_settings: { project_id: nil }) }
  end

  class ProjectSecuritySetting < ActiveRecord::Base
    belongs_to :project, inverse_of: :security_setting
  end

  def up
    return unless Gitlab.ee? # Security Settings available only in EE version

    Project.without_security_settings.select(:id).in_batches do |relation|
      project_ids = relation.pluck(:id)

      BackgroundMigrationWorker.perform_async([MIGRATION, project_ids])
    end
  end

  # We're adding data so no need for rollback
  def down
  end
end

