# frozen_string_literal: true

class CreateIncidentManagementIssuableEscalations < ActiveRecord::Migration[6.1]
  DOWNTIME = false
  IDX_ISSUE = 'index_im_issuable_escalations_on_issue_id'
  IDX_POLICY = 'index_im_issuable_escalations_on_policy_id'

  def change
    create_table :incident_management_issuable_escalations do |t|
      t.references :issue, foreign_key: { on_delete: :cascade }, index: { unique: true, name: IDX_ISSUE }, null: false
      t.references :policy,
        foreign_key: { to_table: :incident_management_escalation_policies, on_delete: :cascade },
        index: { name: IDX_POLICY },
        null: false
      t.datetime_with_timezone :last_notified_at, null: false
      t.timestamps_with_timezone null: false
    end
  end
end
