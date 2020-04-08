# frozen_string_literal: true

module ComplianceManagement
  module ComplianceFramework
    module ProjectSettingsHelper
      def compliance_framework_options
        option_values = compliance_framework_option_values
        ProjectSettings.frameworks.map { |k, _v| [option_values.fetch(k.to_sym), k] }
      end

      def compliance_framework_option_values
        {
            gdpr: s_('ComplianceFramework|GDPR - General Data Protection Regulation'),
            hipaa: s_('ComplianceFramework|HIPAA - Health Insurance Portability and Accountability Act'),
            pci_dss: s_('ComplianceFramework|PCI-DSS - Payment Card Industry-Data Security Standard'),
            soc_2: s_('ComplianceFramework|SOC 2 - Service Organization Control 2'),
            sox: s_('ComplianceFramework|SOX - Sarbanes-Oxley')
        }.freeze
      end
    end
  end
end
