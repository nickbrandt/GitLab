# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class MigrateApproverToApprovalRulesCheckProgress
      RESCHEDULE_DELAY = 1.day

      def perform
        if remaining('MergeRequest') == 0 && remaining('Project') == 0
          Feature.enable(:approval_rule)
        else
          BackgroundMigrationWorker.perform_in(RESCHEDULE_DELAY, self.class.name)
        end
      end

      private

      def remaining(class_name)
        target_type = ActiveRecord::Base.connection.quote(class_name)

        sql_old_schema = <<-SQL.strip_heredoc
          SELECT count(*) FROM (
            SELECT target_id FROM "approvers" WHERE "approvers"."target_type" = #{target_type}
            UNION
            SELECT target_id FROM "approver_groups" WHERE "approver_groups"."target_type" = #{target_type}
          ) AS target_count
        SQL

        sql_new_schema = <<-SQL.strip_heredoc
          SELECT count(distinct #{class_name.foreign_key}) from approval_#{class_name.underscore}_rules
        SQL

        count(sql_old_schema) - count(sql_new_schema)
      end

      def count(sql)
        ActiveRecord::Base.connection.exec_query(sql).first['count']
      end
    end
  end
end
