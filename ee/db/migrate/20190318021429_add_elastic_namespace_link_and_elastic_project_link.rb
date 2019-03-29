# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddElasticNamespaceLinkAndElasticProjectLink < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :elasticsearch_indexed_namespaces, id: false do |t|
      t.timestamps_with_timezone null: false

      t.references :namespace, nil: false, index: { unique: true }, foreign_key: { on_delete: :cascade }
    end

    create_table :elasticsearch_indexed_projects, id: false do |t|
      t.timestamps_with_timezone null: false

      t.references :project, nil: false, index: { unique: true }, foreign_key: { on_delete: :cascade }
    end
  end
end
