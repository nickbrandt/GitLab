# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CreateJiraConnectInstallations < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :jira_connect_installations, id: :bigserial do |t|
      t.string :client_key
      t.string :encrypted_shared_secret
      t.string :encrypted_shared_secret_iv
      t.string :base_url
    end

    add_index :jira_connect_installations, :client_key, unique: true
  end
end
