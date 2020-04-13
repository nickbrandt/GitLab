# frozen_string_literal: true

class SubscriptionPresenter < Gitlab::View::Presenter::Delegated
  presents :subscription

  def block_changes?
    expired?
  end

  def plan
    namespace.try(:actual_plan_name)
  end

  def notify_admins?
    remaining_days && remaining_days < 30
  end

  def notify_users?
    false
  end

  def expires_at
    end_date
  end
  alias_method :block_changes_at, :expires_at

  def remaining_days
    return unless end_date

    (end_date - Date.today).to_i
  end

  def will_block_changes?
    true
  end
end
