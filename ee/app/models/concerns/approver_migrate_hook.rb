# frozen_string_literal: true
#
# Sync up old models (Approver and ApproverGroup)
# to new models (ApprovalMergeRequestRule and ApprovalProjectRule)
#
# TODO: remove once #1979 is closed

module ApproverMigrateHook
  extend ActiveSupport::Concern

  included do
    after_commit :schedule_approval_migration, on: [:create, :destroy]
  end

  def schedule_approval_migration
    # After merge, approval information is frozen
    return if target.is_a?(MergeRequest) && target.merged?

    Gitlab::BackgroundMigration::MigrateApproverToApprovalRules.new.perform(target.class.name, target.id, sync_code_owner_rule: false)
  end
end
