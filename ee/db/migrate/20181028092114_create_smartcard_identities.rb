# frozen_string_literal: true

class CreateSmartcardIdentities < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :smartcard_identities, id: :bigserial do |t|
      t.references :user, null: false, index: true, foreign_key: { on_delete: :cascade }
      t.string 'subject', null: false
      t.string 'issuer', null: false
    end
  end
end
