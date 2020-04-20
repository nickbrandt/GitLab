# frozen_string_literal: true
module EE
  module RunnersHelper
    include ::Gitlab::Utils::StrongMemoize

    def ci_usage_warning_message(namespace, project)
      message = [ci_usage_base_message(namespace)]

      return unless message.any?

      if ::Gitlab.com? && can?(current_user, :admin_project, project)
        message << purchase_shared_runner_minutes_link
      elsif namespace.shared_runners_minutes_used?
        message << s_('Pipelines|Pipelines will not run anymore on shared Runners.')
      end

      message.join(' ').html_safe
    end

    def show_buy_ci_minutes?(project, namespace)
      return false unless experiment_enabled?(:ci_notification_dot) || experiment_enabled?(:buy_ci_minutes_version_a)

      show_out_of_ci_minutes_notification?(project, namespace)
    end

    def show_ci_minutes_notification_dot?(project, namespace)
      return false unless experiment_enabled?(:ci_notification_dot)

      show_out_of_ci_minutes_notification?(project, namespace)
    end

    private

    def show_out_of_ci_minutes_notification?(project, namespace)
      strong_memoize(:show_out_of_ci_minutes_notification) do
        next unless project&.persisted? || namespace&.persisted?

        context = ::Ci::Minutes::Context.new(project, namespace)
        threshold = ::Ci::Minutes::Threshold.new(current_user, context.level)
        threshold.warning_reached? && context.namespace.all_pipelines.for_user(current_user).any?
      end
    end

    def purchase_shared_runner_minutes_link
      link = link_to(_("Click here"), EE::SUBSCRIPTIONS_PLANS_URL, target: '_blank', rel: 'noopener')

      link + s_("Pipelines| to purchase more minutes.")
    end

    def ci_usage_base_message(namespace)
      if namespace.shared_runners_minutes_used?
        s_("Pipelines|%{namespace_name} has exceeded its pipeline minutes quota.") % { namespace_name: namespace.name }
      elsif namespace.shared_runners_remaining_minutes_below_threshold?
        s_("Pipelines|%{namespace_name} has less than %{notification_level}%% of CI minutes available.") % { namespace_name: namespace.name, notification_level: namespace.last_ci_minutes_usage_notification_level }
      end
    end
  end
end
