# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddVerificationForDesigns < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table "project_design_states", id: :serial, force: :cascade do |t|
      t.integer "project_id", null: false
      t.binary "verification_checksum"
      t.string "last_verification_failure"
      t.datetime_with_timezone "retry_at"
      t.integer "retry_count"
      t.datetime_with_timezone "last_verification_ran_at"

      t.index ["last_verification_failure"], name: "idx_design_states_on_failure_partial", where: "(last_verification_failure IS NOT NULL)"
      t.index ["project_id", "last_verification_ran_at"], name: "idx_design_states_on_last_verification_ran_at", where: "((verification_checksum IS NOT NULL) AND (last_verification_failure IS NULL))"
      t.index ["project_id"], name: "idx_design_states_outdated_checksums", where: "((verification_checksum IS NULL) AND (last_verification_failure IS NULL))"
      t.index ["project_id"], name: "index_project_design_states_on_project_id", unique: true
    end
  end
end
