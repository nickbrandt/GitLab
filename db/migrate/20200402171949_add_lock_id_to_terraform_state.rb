# frozen_string_literal: true

class AddLockIdToTerraformState < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :terraform_states, :lock_xid, :string, limit: 255
    add_column :terraform_states, :locked_at, :datetime_with_timezone
    add_reference :terraform_states, :locked_by, foreign_key: { to_table: :users } # rubocop:disable Migration/AddReference (table not used yet)
  end
end
