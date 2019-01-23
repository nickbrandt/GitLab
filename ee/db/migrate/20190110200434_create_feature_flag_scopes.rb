# frozen_string_literal: true

class CreateFeatureFlagScopes < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :operations_feature_flag_scopes, id: :bigserial do |t|
      t.bigint :feature_flag_id, null: false
      t.timestamps_with_timezone null: false
      t.boolean :active, null: false
      t.string :environment_scope, default: "*", null: false
      t.foreign_key :operations_feature_flags, column: :feature_flag_id, on_delete: :cascade

      t.index [:feature_flag_id, :environment_scope],
        unique: true,
        name: 'index_feature_flag_scopes_on_flag_id_and_environment_scope'
    end
  end
end
