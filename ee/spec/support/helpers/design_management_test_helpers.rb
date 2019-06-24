# frozen_string_literal: true

module DesignManagementTestHelpers
  def enable_design_management
    stub_licensed_features(design_management: true)
    stub_lfs_setting(enabled: true)
  end
end
