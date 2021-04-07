# frozen_string_literal: true
# rubocop:disable Style/Documentation

module EE
  module Gitlab
    module BackgroundMigration
      module RemoveInaccessibleEpicIssueLinks
        extend ::Gitlab::Utils::Override

        class EpicIssue < ActiveRecord::Base
          self.table_name = 'epic_issues'
        end

        override :perform
        def perform(group_ids)
          group_ids.each do |group_id|
            epic_issue_ids_to_delete = inaccessible_epic_issue_links(group_id).pluck('id')
            next if epic_issue_ids_to_delete.empty?

            logger.info(
              message: 'Deleting epic_issues',
              epic_issue_ids: epic_issue_ids_to_delete,
              count: epic_issue_ids_to_delete.size
            )
            EpicIssue.where(id: epic_issue_ids_to_delete).delete_all
          end
        end

        private

        def logger
          @logger ||= ::Gitlab::BackgroundMigration::Logger.build
        end

        def inaccessible_epic_issue_links(group_id)
          ApplicationRecord.connection.execute(<<-SQL.squish)
            SELECT epic_issues.* FROM epic_issues
            INNER JOIN epics ON epics.id = epic_issues.epic_id
            INNER JOIN issues ON issues.id = epic_issues.issue_id
            INNER JOIN projects ON projects.id = issues.project_id
            WHERE epics.group_id = #{group_id}
              AND projects.namespace_id NOT IN (WITH RECURSIVE base_and_descendants AS (
                (SELECT namespaces.* FROM namespaces
                  WHERE namespaces.type = 'Group'
                  AND namespaces.id = #{group_id})
                UNION
                (SELECT namespaces.* FROM namespaces, base_and_descendants
                  WHERE namespaces.type = 'Group'
                  AND namespaces.parent_id = base_and_descendants.id))
                SELECT namespaces.id
                FROM base_and_descendants AS namespaces);
          SQL
        end
      end
    end
  end
end
