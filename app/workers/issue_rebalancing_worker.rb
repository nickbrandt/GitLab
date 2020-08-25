# frozen_string_literal: true

class IssueRebalancingWorker
  include ApplicationWorker

  idempotent!
  urgency :low
  feature_category :issue_tracking

  def perform(issue_id)
    issue = Issue.find(issue_id)

    rebalance(issue)
  rescue ActiveRecord::RecordNotFound, IssueRebalancingService::TooManyIssues => e
    Gitlab::ErrorTracking.log_exception(e, issue_id: issue_id)
  end

  private

  def rebalance(issue)
    gates = [issue.project, issue.project.group].compact
    return unless gates.any? { |gate| Feature.enabled?(:rebalance_issues, gate) }

    IssueRebalancingService.new(issue).execute
  end
end
