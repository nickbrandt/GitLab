# frozen_string_literal: true

module TrialStatusWidgetHelper
  def billing_plans_and_trials_available?
    ::Gitlab::CurrentSettings.should_check_namespace_plan?
  end

  def eligible_for_trial_status_widget?(group)
    group.trial_active? && can?(current_user, :admin_namespace, group)
  end

  def plan_title_for_group(group)
    group.gitlab_subscription&.plan_title
  end
end
