# frozen_string_literal: true

class ChangeDefaultValueOfThrottleProtectedPaths < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def change
    change_column_default :application_settings, :throttle_protected_paths_enabled, from: true, to: false
  end
end
