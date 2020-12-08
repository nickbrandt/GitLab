# frozen_string_literal: true

module TrialStatusWidgetExperimentHelper
  def eligible_for_trial_status_widget_experiment?(group)
    group.trial_active? &&
      current_user.member_of?(group, min_access_level: ::Gitlab::Access::OWNER) &&
      !current_user.has_non_trial_paid_namespace?
  end

  def should_show_trial_status_widget?(group)
    return false unless ::Gitlab::CurrentSettings.should_check_namespace_plan?

    experiment_key = :show_namespace_trial_status_in_sidebar
    experiment_enabled?(experiment_key, subject: group) &&
      eligible_for_trial_status_widget_experiment?(group)
  end

  def record_trial_status_widget_experiment_participant(group)
    return unless eligible_for_trial_status_widget_experiment?(group)

    experiment_key = :show_namespace_trial_status_in_sidebar
    record_experiment_subject(experiment_key, group)
  end

  def record_trial_status_widget_experiment_conversion(group)
    return unless eligible_for_trial_status_widget_experiment?(group)

    experiment_key = :show_namespace_trial_status_in_sidebar
    record_experiment_conversion_event(experiment_key, subject: group)
  end

  private

  def experiment_debug_info_for_group(group)
    experiment_key = :show_namespace_trial_status_in_sidebar

    {
      'ApplicationSetting#check_namespace_plan' => ::Gitlab::CurrentSettings.should_check_namespace_plan?,
      'Experimentation.active?' => ::Gitlab::Experimentation.active?(experiment_key),
      '@group.trial_active?' => @group.trial_active?,
      '!current_user.has_non_trial_paid_namespace?' => !current_user.has_non_trial_paid_namespace?,
      'experiment_enabled?' => experiment_enabled?(experiment_key, subject: @group),
      'have experiment_subject' => Experiment.find_by(name: experiment_key)&.experiment_subjects&.find_by_subject(@group).present? # rubocop:disable CodeReuse/ActiveRecord
    }
  end
end
