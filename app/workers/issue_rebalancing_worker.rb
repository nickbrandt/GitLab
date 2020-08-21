# frozen_string_literal: true

class IssueRebalancingWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  idempotent!
  urgency :low
  feature_category :issue_tracking

  def perform(issue_id)
    issue = Issue.find(issue_id)

    rebalance(issue)
  rescue ActiveRecord::RecordNotFound, IssueRebalancingService::TooManyIssues, RelativePositioning::NoSpaceLeft => e
    Sidekiq.logger.warn(e)
  end

  private

  def rebalance(issue)
    IssueRebalancingService.new(issue).execute
  end
end
