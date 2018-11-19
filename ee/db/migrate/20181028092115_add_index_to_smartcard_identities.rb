# frozen_string_literal: true

class AddIndexToSmartcardIdentities < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :smartcard_identities, [:subject, :issuer], unique: true
  end

  def down
    remove_concurrent_index :smartcard_identities, [:subject, :issuer]
  end
end
