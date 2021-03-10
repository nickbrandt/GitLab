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
          epic_issue_ids_to_delete = inaccessible_epic_issue_links(group_ids.join(', ')).pluck('id')

          logger.info(message: 'Deleting epic_issues', epic_issue_ids: epic_issue_ids_to_delete)
          EpicIssue.where(id: epic_issue_ids_to_delete).delete_all
        end

        private

        def logger
          @logger ||= ::Gitlab::BackgroundMigration::Logger.build
        end

        def inaccessible_epic_issue_links(group_ids)
          ApplicationRecord.connection.execute(<<-SQL.squish)
            SELECT epic_issues.* FROM epic_issues
            INNER JOIN epics ON epics.id = epic_issues.epic_id
            INNER JOIN issues ON issues.id = epic_issues.issue_id
            INNER JOIN projects ON projects.id = issues.project_id
            WHERE epics.group_id IN (#{group_ids})
              AND projects.namespace_id NOT IN (WITH RECURSIVE base_and_descendants AS (
                (SELECT namespaces.* FROM namespaces
                  WHERE namespaces.type = 'Group'
                  AND namespaces.id IN (#{group_ids}))
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
