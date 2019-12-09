# frozen_string_literal: true

# Finders::MergeRequest class
#
# Used to filter MergeRequests collections for compliance dashboard
#
# Arguments:
#   current_user - which user use
#   params:
#     group_id: integer
#
class MergeRequestsComplianceFinder < MergeRequestsFinder
  def execute
    sql = super
      .select('DISTINCT ON (merge_requests.target_project_id) merge_requests.*, merge_request_metrics.merged_at')
      .to_sql

    # rubocop: disable CodeReuse/ActiveRecord
    MergeRequest
      .from([Arel.sql("(#{sql}) AS #{MergeRequest.table_name}")])
      .order('merged_at DESC')
    # rubocop: enable CodeReuse/ActiveRecord
  end

  private

  def params
    finder_options = {
      scope: :all,
      state: :merged,
      sort: :by_merged_at,
      include_subgroups: true,
      attempt_group_search_optimizations: true
    }
    super.merge(finder_options)
  end
end
