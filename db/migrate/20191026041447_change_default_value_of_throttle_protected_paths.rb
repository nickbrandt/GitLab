# frozen_string_literal: true

class ChangeDefaultValueOfThrottleProtectedPaths < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    change_column_default :application_settings, :throttle_protected_paths_enabled, false

    # Because we already set the value to true in the previous
    # migration, this feature was switched on inadvertently in GitLab
    # 12.4. This migration toggles it back off to ensure we don't
    # inadvertently block legitimate users. The admin will have to
    # re-enable it in the application settings.
    execute "UPDATE application_settings SET throttle_protected_paths_enabled = #{false_value}"
  end

  def down
    change_column_default :application_settings, :throttle_protected_paths_enabled, true

    execute "UPDATE application_settings SET throttle_protected_paths_enabled = #{true_value}"
  end
end
