class CreateScimOauthAccessTokens < ActiveRecord::Migration[5.0]
  def change
    create_table :scim_oauth_access_tokens do |t|
      t.timestamps_with_timezone null: false
      t.references :group, null: false, index: false
      t.string "token", null: false

      t.index [:group_id, :token], unique: true
      t.foreign_key :namespaces, column: :group_id, on_delete: :cascade
    end
  end
end
