# frozen_string_literal: true

module ComplianceManagement
  module Frameworks
    def compliance_pipeline_configuration_available?
      return true unless params.key?(:pipeline_configuration_full_path)

      available = can?(current_user, :manage_group_level_compliance_pipeline_config, framework)
      params.delete(:pipeline_configuration_full_path) unless available

      available
    end
  end
end
