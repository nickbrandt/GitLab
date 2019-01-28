# frozen_string_literal: true

class CreateDefaultScopeToFeatureFlags < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    execute <<~SQL
      INSERT INTO operations_feature_flag_scopes (feature_flag_id, environment_scope, active, created_at, updated_at)
      SELECT id, '*', active, created_at, updated_at
      FROM operations_feature_flags
      WHERE NOT EXISTS (
        SELECT 1
        FROM operations_feature_flag_scopes
        WHERE operations_feature_flags.id = operations_feature_flag_scopes.feature_flag_id AND
          environment_scope = '*'
      );
    SQL
  end

  def down
    execute <<~SQL
      DELETE FROM operations_feature_flag_scopes WHERE environment_scope = '*';
    SQL
  end
end
