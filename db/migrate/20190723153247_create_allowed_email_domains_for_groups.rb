# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CreateAllowedEmailDomainsForGroups < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def up
    create_table :allowed_email_domains do |t|
      t.references :group, references: :namespace,
        column: :group_id,
        type: :integer,
        null: false,
        index: true
      t.string :domain, null: false
      t.foreign_key :namespaces, column: :group_id, on_delete: :cascade

      t.timestamps_with_timezone null: false
    end
  end

  def down
    remove_foreign_key :allowed_email_domains, :namespaces
    drop_table :allowed_email_domains
  end
end
