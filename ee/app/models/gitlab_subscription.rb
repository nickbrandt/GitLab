# frozen_string_literal: true

class GitlabSubscription < ApplicationRecord
  default_value_for(:start_date) { Date.today }
  after_create_commit :log_previous_state_for_create
  before_update :log_previous_state_for_update
  after_destroy_commit :log_previous_state_for_destroy

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

  def expired?
    return false unless end_date

    end_date < Date.today
  end

  def upgradable?
    has_a_paid_hosted_plan? &&
      !expired? &&
      plan_name != Plan::PAID_HOSTED_PLANS[-1]
  end

  def plan_code=(code)
    code ||= Plan::FREE

    self.hosted_plan = Plan.find_by(name: code)
  end

  private

  def log_previous_state_for_create
    log_previous_state_to_history(:gitlab_subscription_created)
  end

  def log_previous_state_for_update
    attrs = self.attributes.merge(self.attributes_in_database)
    log_previous_state_to_history(:gitlab_subscription_updated, attrs)
  end

  def log_previous_state_for_destroy
    attrs = self.attributes
    log_previous_state_to_history(:gitlab_subscription_destroyed, attrs)
  end

  def log_previous_state_to_history(change_type, attrs = {})
    attrs['gitlab_subscription_created_at'] = attrs['created_at']
    attrs['gitlab_subscription_updated_at'] = attrs['updated_at']
    attrs['gitlab_subscription_id'] = self.id
    attrs['change_type'] = change_type

    omitted_attrs = %w(id created_at updated_at)

    GitlabSubscriptionHistory.create(attrs.except(*omitted_attrs))
  end

  def hosted?
    namespace_id.present?
  end
end
