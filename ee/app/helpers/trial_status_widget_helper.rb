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

  def show_trial_status_widget?(group)
    return false unless billing_plans_and_trials_available?

    eligible_for_trial_status_widget?(group)
  end

  # Note: This method has a side-effect in that it records the given group as a
  # participant in the experiment (if the experiment is active at all) in the
  # `experiment_subjects` table.
  def trial_status_widget_experiment_enabled?(group)
    experiment_key = :show_trial_status_in_sidebar

    # Record the top-level group as a Growth::Conversion experiment participant
    record_experiment_group(experiment_key, group)

    experiment_enabled?(experiment_key, subject: group)
  end
end
