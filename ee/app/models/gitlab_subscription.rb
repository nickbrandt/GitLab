# frozen_string_literal: true

class GitlabSubscription < ActiveRecord::Base
  default_value_for :start_date, Date.today

  belongs_to :namespace
  belongs_to :hosted_plan, class_name: 'Plan'

  validates :seats, :start_date, presence: true
  validates :namespace_id, uniqueness: true, allow_blank: true

  delegate :name, :title, to: :hosted_plan, prefix: :plan, allow_nil: true

  scope :with_a_paid_hosted_plan, -> do
    joins(:hosted_plan).where(trial: false, 'plans.name' => Plan::PAID_HOSTED_PLANS)
  end

  def seats_in_use
    namespace.billable_members_count
  end

  # The purpose of max_seats_used is similar to what we do for EE licenses
  # with the historical max. We want to know how many extra users the customer
  # has added to their group (users above the number purchased on their subscription).
  # Then, on the next month we're going to automatically charge the customers for those extra users.
  def seats_owed
    return 0 unless has_a_paid_hosted_plan?

    [0, max_seats_used - seats].max
  end

  def has_a_paid_hosted_plan?
    !trial? &&
      hosted? &&
      seats > 0 &&
      Plan::PAID_HOSTED_PLANS.include?(plan_name)
  end

  def plan_code=(code)
    code ||= Namespace::FREE_PLAN

    self.hosted_plan = Plan.find_by(name: code)
  end

  private

  def hosted?
    namespace_id.present?
  end
end
