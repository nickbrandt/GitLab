# frozen_string_literal: true

module SubscriptionsHelper
  def subscription_data
    {
      setup_for_company: (current_user.setup_for_company == true).to_s,
      full_name: current_user.name,
      plan_data: plan_data.to_json,
      plan_id: params[:plan_id]
    }
  end

  def plan_title
    @plan_title ||= subscription.hosted_plan.title
  end

  def subscription_seats
    @subscription_seats ||= subscription.seats
  end

  private

  def plan_data
    FetchSubscriptionPlansService.new(plan: :free).execute
      .map(&:symbolize_keys)
      .reject { |plan| plan[:free] }
      .map { |plan| plan.slice(:id, :code, :price_per_year) }
  end

  def subscription
    @subscription ||= @group.gitlab_subscription
  end
end
