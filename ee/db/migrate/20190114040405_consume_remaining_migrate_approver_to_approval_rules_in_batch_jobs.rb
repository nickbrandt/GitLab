# frozen_string_literal: true

class ConsumeRemainingMigrateApproverToApprovalRulesInBatchJobs < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  # Number of MRs to join in order to search for wrong MR ids.
  # Wrong MRs appear to be aggregated in groups,
  # because migration was grouped in blocks of 3000,
  # and when one MR fails, later MRs in that group are not be migrated.
  #
  # Double the size since difference between lower and higher id of the group
  # are a little bigger than 3000.
  #
  # By using this smaller join size, the query is faster.
  JOIN_SIZE = 6000
  # A bound for doing searches.
  # Without it a search for the next bad MR can timeout if that MR's id is really high.
  BOUND_SIZE = 1000000
  BASE_QUERY = <<~SQL
    SELECT DISTINCT merge_requests.id FROM merge_requests
    LEFT JOIN approval_merge_request_rules
    ON merge_requests.id = approval_merge_request_rules.merge_request_id AND approval_merge_request_rules.code_owner IS FALSE
    LEFT JOIN approvers
    ON merge_requests.id = approvers.target_id AND approvers.target_type = 'MergeRequest'
    LEFT JOIN approver_groups
    ON merge_requests.id = approver_groups.target_id AND approver_groups.target_type = 'MergeRequest'
    WHERE (approval_merge_request_rules.id IS NULL) AND (approvers.id IS NOT NULL OR approver_groups.id IS NOT NULL)
  SQL

  class MergeRequest < ActiveRecord::Base
    self.table_name = 'merge_requests'
  end

  disable_ddl_transaction!

  def up
    ApplicationSetting.reset_column_information

    Gitlab::BackgroundMigration.steal('MigrateApproverToApprovalRulesInBatch', retry_dead_jobs: true)

    process_unmigrated
  end

  def down
  end

  private

  def process_unmigrated
    bad_ids = []

    max_id = MergeRequest.maximum(:id)

    return if max_id.nil?

    (0..max_id).step(BOUND_SIZE) do |lower_bound|
      bad_ids.concat search_bound(lower_bound, lower_bound + BOUND_SIZE)
    end

    bad_ids.uniq!
    bad_ids.each do |id|
      Gitlab::BackgroundMigration::MigrateApproverToApprovalRules.new.perform('MergeRequest', id)
    end
  end

  def search_bound(lower_bound, upper_bound)
    bad_ids = []

    loop do
      # search for next wrong MR
      lower_bound = exec_query("#{BASE_QUERY} AND merge_requests.id BETWEEN #{lower_bound} AND #{upper_bound} ORDER BY merge_requests.id ASC LIMIT 1").dig(0, 0)

      return bad_ids if lower_bound.nil?

      end_id = lower_bound + JOIN_SIZE

      bad_ids.concat exec_query("#{BASE_QUERY} AND merge_requests.id BETWEEN #{lower_bound} AND #{end_id} ORDER BY merge_requests.id ASC").flatten

      lower_bound = end_id + 1
    end
  end

  def exec_query(query)
    ActiveRecord::Base.connection.exec_query(query).rows
  end
end
