# frozen_string_literal: true

class CreateSecurityFindingsTable < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    create_table :security_findings, if_not_exists: true do |t|
      t.references :scan, null: false
      t.references :scanner, null: false
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
