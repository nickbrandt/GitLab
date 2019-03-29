# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddElasticsearchLimitIndexingToApplicationSetting < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default :application_settings, :elasticsearch_limit_indexing, :boolean, default: false, allow_null: false
  end

  def down
    remove_column :application_settings, :elasticsearch_limit_indexing
  end
end
