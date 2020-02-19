# frozen_string_literal: true

class CreateUserDetails < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    with_lock_retries do
      create_table :user_details, id: false do |t|
        t.references :user, index: false, foreign_key: { on_delete: :cascade }, null: false
        t.string :bio, null: false, default: '', limit: 255
        t.string :location, null: false, default: '', limit: 255
        t.string :organization, null: false, default: '', limit: 255
        t.string :linkedin, null: false, default: '', limit: 2048
        t.string :twitter, null: false, default: '', limit: 2048
        t.string :skype, null: false, default: '', limit: 2048
        t.string :website_url, null: false, default: '', limit: 2048
      end
    end

    add_index :user_details, :user_id, unique: true
  end
end
