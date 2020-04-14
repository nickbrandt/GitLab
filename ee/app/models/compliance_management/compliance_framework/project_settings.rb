# frozen_string_literal: true

module ComplianceManagement
  module ComplianceFramework
    class ProjectSettings < ApplicationRecord
      self.table_name = 'project_compliance_framework_settings'
      self.primary_key = :project_id

      belongs_to :project

      enum framework: {
        gdpr: 1,    # General Data Protection Regulation
        hipaa: 2,   # Health Insurance Portability and Accountability Act
        pci_dss: 3, # Payment Card Industry-Data Security Standard
        soc_2: 4,   # Service Organization Control 2
        sox: 5      # Sarbanes-Oxley
      }

      validates :project, presence: true
      validates :framework, uniqueness: { scope: [:project_id] }
      validates :framework, inclusion: { in: self.frameworks.keys }
    end
  end
end
