# frozen_string_literal: true
#
# Used to filter MergeRequests collections for compliance dashboard
#
# Arguments:
#   current_user - which user calls a class
#   params:
#     group_id: integer
#     preloads: array of associations to preload
#
class MergeRequestsComplianceFinder < MergeRequestsFinder
  def execute
    # rubocop: disable CodeReuse/ActiveRecord
    lateral = Event
      .select(:created_at, :target_id)
      .where('projects.id = project_id')
      .merged_action
      .recent
      .limit(1)
      .to_sql

    sql = params.find_group_projects.arel.as('projects').to_sql
    records = Project
      .select('projects.id, events.target_id as merge_request_id')
      .from([Arel.sql("#{sql} JOIN LATERAL (#{lateral}) #{Event.table_name} ON true")])
      .order('events.created_at DESC')
    select_sorted_mrs(records)
    # rubocop: enable CodeReuse/ActiveRecord
  end

  private

  def params
    finder_options = {
      include_subgroups: true,
      attempt_group_search_optimizations: true
    }
    super.merge(finder_options)
  end

  def select_sorted_mrs(records)
    hash = {}
    records.each { |row| hash[row['merge_request_id']] = nil }
    mrs = MergeRequest.where(id: hash.keys).preload(preloads) # rubocop: disable CodeReuse/ActiveRecord

    mrs.each { |mr| hash[mr.id] = mr }

    hash.compact!
    hash.values # sorted MRs
  end

  def preloads
    [:approved_by_users, :metrics, source_project: :route, target_project: :namespace]
  end
end
