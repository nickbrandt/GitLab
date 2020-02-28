# frozen_string_literal: true

module Groups::SecurityFeaturesHelper
  def group_level_security_dashboard_available?(group)
    group.feature_available?(:security_dashboard)
  end

  def group_level_compliance_dashboard_available?(group)
    group.feature_available?(:group_level_compliance_dashboard) &&
    can?(current_user, :read_group_compliance_dashboard, group)
  end

  def group_level_credentials_inventory_available?(group)
    can?(current_user, :read_group_credentials_inventory, group) &&
    group.feature_available?(:credentials_inventory) &&
    group.enforced_group_managed_accounts?
  end

  def primary_group_level_security_feature_path(group)
    if group_level_security_dashboard_available?(group)
      group_security_dashboard_path(group)
    elsif group_level_compliance_dashboard_available?(group)
      group_security_compliance_dashboard_path(group)
    elsif group_level_credentials_inventory_available?(group)
      group_security_credentials_path(group)
    end
  end
end
