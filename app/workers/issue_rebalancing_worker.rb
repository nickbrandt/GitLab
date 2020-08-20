# frozen_string_literal: true

class IssueRebalancingWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  def perform(issue_id)
    issue = Issue.find(issue_id)

    rebalance(issue)
  rescue ActiveRecord::RecordNotFound => e
    Sidekiq.logger.warn(e)
  end

  private

  def rebalance(issue)
    IssueRebalancingService.new(issue).execute
  end
end
