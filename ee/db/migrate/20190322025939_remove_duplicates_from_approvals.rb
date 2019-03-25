# frozen_string_literal: true

class RemoveDuplicatesFromApprovals < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    if Gitlab::Database.mysql?
      execute <<-SQL
        DELETE FROM a
        USING approvals AS a
        INNER JOIN (
          SELECT user_id, merge_request_id, MIN(id) as min_id
          FROM approvals
          GROUP BY user_id, merge_request_id
          HAVING COUNT(id) > 1
        ) as approvals_with_duplicates
        ON approvals_with_duplicates.user_id = a.user_id
        AND approvals_with_duplicates.merge_request_id = a.merge_request_id
        WHERE approvals_with_duplicates.min_id <> a.id;
      SQL
    else
      execute <<-SQL
        DELETE FROM approvals
        USING (
          SELECT user_id, merge_request_id, MIN(id) as min_id
          FROM approvals
          GROUP BY user_id, merge_request_id
          HAVING COUNT(id) > 1
        ) as approvals_with_duplicates
        WHERE approvals_with_duplicates.user_id = approvals.user_id
        AND approvals_with_duplicates.merge_request_id = approvals.merge_request_id
        AND approvals_with_duplicates.min_id <> approvals.id;
      SQL
    end
  end

  def down
  end
end
