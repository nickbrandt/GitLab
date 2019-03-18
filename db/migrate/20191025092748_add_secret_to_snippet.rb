# frozen_string_literal: true

class AddSecretToSnippet < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    add_column :snippets, :encrypted_secret_token, :string, limit: 255
    add_column :snippets, :encrypted_secret_token_iv, :string, limit: 255
    add_column :snippets, :encrypted_secret_token_salt, :string, limit: 255
  end
end
