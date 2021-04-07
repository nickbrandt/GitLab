# frozen_string_literal: true

module ComplianceManagement
  class FrameworkPolicy < BasePolicy
    delegate { @subject.namespace }

    condition(:custom_compliance_frameworks_enabled) do
      @subject.namespace.feature_available?(:custom_compliance_frameworks) &&
        Feature.enabled?(:ff_custom_compliance_frameworks, @subject.namespace, default_enabled: :yaml)
    end

    condition(:group_level_compliance_pipeline_enabled) do
      @subject.namespace.feature_available?(:evaluate_group_level_compliance_pipeline) &&
        Feature.enabled?(:ff_evaluate_group_level_compliance_pipeline, @subject.namespace)
    end

    rule { can?(:owner_access) & custom_compliance_frameworks_enabled }.policy do
      enable :manage_compliance_framework
    end

    rule { can?(:read_namespace) & custom_compliance_frameworks_enabled }.enable :read_compliance_framework

    rule { can?(:owner_access) & group_level_compliance_pipeline_enabled }.policy do
      enable :manage_group_level_compliance_pipeline_config
    end
  end
end
