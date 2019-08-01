# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RenameApplicationSettingsSnowplowCollectorUriColumn < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    rename_column :application_settings, :snowplow_collector_uri, :snowplow_collector_hostname
  end
end
