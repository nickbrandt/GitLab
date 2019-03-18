# frozen_string_literal: true

class CreateScimOauthAccessTokens < ActiveRecord::Migration[5.0]
  DOWNTIME = false

  def change
    create_table :scim_oauth_access_tokens do |t|
      t.timestamps_with_timezone null: false
      t.references :group, null: false, index: false
      t.string :token_encrypted, null: false

      t.index [:group_id, :token_encrypted], unique: true
      t.foreign_key :namespaces, column: :group_id, on_delete: :cascade
    end
  end
end
