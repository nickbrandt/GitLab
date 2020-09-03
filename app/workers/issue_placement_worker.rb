# frozen_string_literal: true

class IssuePlacementWorker
  include ApplicationWorker

  idempotent!
  feature_category :issue_tracking
  urgency :high
  worker_resource_boundary :cpu
  weight 2

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(issue_id, placement = :end)
    issue = Issue.find(issue_id)

    # here we are placing not just this issue, but it and all issues created since, and up to five-minutes before.
    # This is to deal with out-of-order execution of the worker, while preserving creation order.
    to_place = Issue
      .relative_positioning_query_base(issue)
      .where(Issue.arel_table[:created_at].gteq(issue.created_at - 5.minutes))
      .order_created_at_desc

    if placement == :end
      Issue.move_nulls_to_end(to_place.to_a.reverse)
    elsif placement == :start
      Issue.move_nulls_to_start(to_place.to_a)
    end
  rescue ActiveRecord::RecordNotFound, RelativePositioning::NoSpaceLeft => e
    Gitlab::ErrorTracking.log_exception(e, issue_id: issue_id, placement: placement)
    IssueRebalancingWorker.perform_async(nil, issue.project_id) if issue && e.is_a?(RelativePositioning::NoSpaceLeft)
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
