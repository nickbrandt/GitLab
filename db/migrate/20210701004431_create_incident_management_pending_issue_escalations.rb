# frozen_string_literal: true

class CreateIncidentManagementPendingIssueEscalations < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  def up
    with_lock_retries do
      execute(<<~SQL)

        CREATE TABLE incident_management_pending_issue_escalations (
          id bigserial NOT NULL,
          issue_id bigint NOT NULL,
          rule_id bigint,
          schedule_id bigint,
          user_id bigint,
          process_at timestamp with time zone NOT NULL,
          created_at timestamp with time zone NOT NULL,
          updated_at timestamp with time zone NOT NULL,
          status smallint NOT NULL,
          PRIMARY KEY (id, process_at)
        ) PARTITION BY RANGE (process_at);

        CREATE INDEX index_incident_management_pending_issue_escalations_on_issue_id
          ON incident_management_pending_issue_escalations USING btree (issue_id);

        CREATE INDEX index_incident_management_pending_issue_escalations_on_rule_id
          ON incident_management_pending_issue_escalations USING btree (rule_id);

        CREATE INDEX index_incident_management_pending_issue_escalations_on_schedule_id
          ON incident_management_pending_issue_escalations USING btree (schedule_id);

        ALTER TABLE incident_management_pending_issue_escalations ADD CONSTRAINT fk_rails_fcbfd9338b
          FOREIGN KEY (schedule_id) REFERENCES incident_management_oncall_schedules(id) ON DELETE CASCADE;

        ALTER TABLE incident_management_pending_issue_escalations ADD CONSTRAINT fk_rails_057c1e3d87
          FOREIGN KEY (rule_id) REFERENCES incident_management_escalation_rules(id) ON DELETE SET NULL;

        ALTER TABLE incident_management_pending_issue_escalations ADD CONSTRAINT fk_rails_8d8de95da9
          FOREIGN KEY (issue_id) REFERENCES issues(id) ON DELETE CASCADE;

        ALTER TABLE incident_management_pending_issue_escalations ADD CONSTRAINT inc_mgmnt_issue_escalations_single_target
          CHECK ((schedule_id IS NOT NULL AND user_id IS NULL) OR
                 (schedule_id IS NULL AND user_id IS NOT NULL));
      SQL
    end
  end

  def down
    with_lock_retries do
      drop_table :incident_management_pending_issue_escalations
    end
  end
end
