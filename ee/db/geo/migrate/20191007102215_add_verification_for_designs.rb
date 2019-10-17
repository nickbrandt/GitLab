# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddVerificationForDesigns < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    change_table :design_registry do |t|
      t.string :last_verification_failure
      t.binary :verification_checksum_sha
      t.boolean :checksum_mismatch, default: false, null: false
      t.boolean :last_check_failed
      t.integer :verification_retry_count
      t.binary :verification_checksum_mismatched

      t.index ["project_id"], name: "idx_checksum_mismatch", where: "(checksum_mismatch = true)"
      t.index ["project_id"], name: "idx_design_registry_checksums_and_failure_partial", where: "((verification_checksum_sha IS NULL) AND (last_verification_failure IS NULL))"
      t.index ["project_id"], name: "idx_design_registry_failure_partial", where: "(last_verification_failure IS NOT NULL)"
      t.index ["retry_count"], name: "idx_design_registry_failed_partial", where: "((retry_count > 0) OR (last_verification_failure IS NOT NULL) OR checksum_mismatch)"
      t.index ["retry_count"], name: "idx_design_registry_pending_partial", where: "((retry_count = 0) AND ((state = 'pending') OR ((verification_checksum_sha IS NULL) AND (last_verification_failure IS NULL))))"
      t.index ["verification_checksum_sha"], name: "idx_design_registry_checksum_sha_partial", where: "(verification_checksum_sha IS NULL)"
    end

    add_column(:design_registry, :last_check_at, :datetime_with_timezone)
    add_column(:design_registry, :last_verification_ran_at, :datetime_with_timezone)
  end
end
