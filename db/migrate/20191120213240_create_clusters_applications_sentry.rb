# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CreateClustersApplicationsSentry < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false
  def change
    # rubocop:disable Migration/AddLimitToStringColumns
    create_table :clusters_applications_sentry do |t|
      t.references :cluster, null: false, unique: true, foreign_key: { on_delete: :cascade }

      t.integer :status, null: false
      t.string :version, null: false # rubocop:disable Migration/AddLimitToStringColumns
      t.string :hostname # rubocop:disable Migration/AddLimitToStringColumns

      t.timestamps_with_timezone null: false

      t.text :status_reason
    end
    # rubocop:enable Migration/AddLimitToStringColumns
  end
end
