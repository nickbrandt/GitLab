# frozen_string_literal: true

class AddVerificationFailureLimitToLfsObjects < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  CONSTRAINT_NAME = 'lfs_object_verification_failure_text_limit'

  def up
    add_text_limit :lfs_objects, :verification_failure, 255, constraint_name: CONSTRAINT_NAME
  end

  def down
    remove_check_constraint(:lfs_objects, CONSTRAINT_NAME)
  end
end
