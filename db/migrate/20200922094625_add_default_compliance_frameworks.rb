# frozen_string_literal: true

class AddDefaultComplianceFrameworks < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers
  disable_ddl_transaction!

  DOWNTIME = false
  DEFAULT_FRAMEWORKS = [
      {
          name: 'GDPR',
          description: 'General Data Protection Regulation',
          color: '#1aaa55',
          id: 1
      },
      {
          name: 'HIPAA',
          description: 'Health Insurance Portability and Accountability Act',
          color: '#1f75cb',
          id: 2
      },
      {
          name: 'PCI-DSS',
          description: 'Payment Card Industry-Data Security Standard',
          color: '#6666c4',
          id: 3
      },
      {
          name: 'SOC 2',
          description: 'Service Organization Control 2',
          color: '#dd2b0e',
          id: 4
      },
      {
          name: 'SOX',
          description: 'Sarbanes-Oxley',
          color: '#fc9403',
          id: 5
      }
  ]

  def up
    rename_column_concurrently :project_compliance_framework_settings, :framework, :framework_id, batch_column_name: :project_id
    DEFAULT_FRAMEWORKS.each do |framework|
      ComplianceManagement::Framework.create!(framework)
    end
    execute("ALTER SEQUENCE compliance_management_frameworks_id_seq RESTART WITH 6;")
    add_concurrent_foreign_key :project_compliance_framework_settings,
                    :compliance_management_frameworks,
                    on_delete: :cascade, validate: false, column: :framework_id
    add_concurrent_index(:project_compliance_framework_settings, :framework_id, name: 'index_project_compliance_framework_settings_framework_id')
  end

  def down
    ComplianceManagement::ComplianceFramework::FRAMEWORKS.each do |_, v|
      ComplianceManagement::Framework.delete(v)
    end

    remove_concurrent_index(:project_compliance_framework_settings, :framework_id, name: 'index_project_compliance_framework_settings_framework_id')
    remove_foreign_key_if_exists :project_compliance_framework_settings, column: :framework_id
    undo_rename_column_concurrently :project_compliance_framework_settings, :framework, :framework_id
  end
end
