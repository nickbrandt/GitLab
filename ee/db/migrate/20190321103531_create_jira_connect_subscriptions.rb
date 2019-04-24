# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CreateJiraConnectSubscriptions < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :jira_connect_subscriptions, id: :bigserial do |t|
      t.references :jira_connect_installation, type: :bigint, foreign_key: { on_delete: :cascade }, index: { name: 'idx_jira_connect_subscriptions_on_installation_id' }, null: false
      t.references :namespace, foreign_key: { on_delete: :cascade }, null: false
      t.timestamps_with_timezone
    end

    add_index :jira_connect_subscriptions, [:jira_connect_installation_id, :namespace_id], unique: true, name: 'idx_jira_connect_subscriptions_on_installation_id_namespace_id'
  end
end
