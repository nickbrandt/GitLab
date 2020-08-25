# frozen_string_literal: true

class CreateSecurityFindingsTable < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    create_table :security_findings, id: :bigserial do |t|
      t.references :scan, null: false, foreign_key: { to_table: :security_scans, on_delete: :cascade }
      t.references :scanner, null: false, foreign_key: { to_table: :vulnerability_scanners, on_delete: :cascade }
      t.integer :severity, limit: 2, index: true, null: false
      t.integer :confidence, limit: 2, index: true, null: false
      t.text :project_fingerprint, index: true, null: false
    end

    add_text_limit :security_findings, :project_fingerprint, 40
  end

  def down
    drop_table :security_findings
  end
end
